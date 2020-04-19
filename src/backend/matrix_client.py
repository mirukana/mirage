# SPDX-License-Identifier: LGPL-3.0-or-later

"""Matrix client and related classes."""

import asyncio
import html
import io
import logging as log
import platform
import re
import sys
import traceback
from contextlib import suppress
from copy import deepcopy
from datetime import datetime, timedelta
from functools import partial
from pathlib import Path
from typing import (
    TYPE_CHECKING, Any, ClassVar, Dict, List, NamedTuple, Optional, Set, Tuple,
    Type, Union,
)
from urllib.parse import urlparse
from uuid import UUID, uuid4

import cairosvg
from PIL import Image as PILImage
from pymediainfo import MediaInfo

import nio
from nio.crypto import AsyncDataT as UploadData
from nio.crypto import async_generator_from_data

from . import __app_name__, __display_name__, utils
from .errors import (
    BadMimeType, InvalidUserId, InvalidUserInContext, MatrixError,
    MatrixNotFound, MatrixTooLarge, UneededThumbnail,
    UserFromOtherServerDisallowed,
)
from .html_markdown import HTML_PROCESSOR as HTML
from .media_cache import Media, Thumbnail
from .models.items import Event, Member, Room, Upload, UploadStatus, ZeroDate
from .models.model_store import ModelStore
from .nio_callbacks import NioCallbacks
from .pyotherside_events import AlertRequested, LoopException

if TYPE_CHECKING:
    from .backend import Backend

if sys.version_info >= (3, 7):
    current_task = asyncio.current_task
else:
    current_task = asyncio.Task.current_task

CryptDict = Dict[str, Any]


class UploadReturn(NamedTuple):
    """Details for an uploaded file."""

    mxc:             str
    mime:            str
    decryption_dict: Dict[str, Any]


class MatrixImageInfo(NamedTuple):
    """Image informations to be passed for Matrix file events."""

    width:  int
    height: int
    mime:   str
    size:   int

    def as_dict(self) -> Dict[str, Union[int, str]]:
        """Return a dict ready to be included in a Matrix file events."""

        return {
            "w":        self.width,
            "h":        self.height,
            "mimetype": self.mime,
            "size":     self.size,
        }


class MatrixClient(nio.AsyncClient):
    """A client for an account to interact with a matrix homeserver."""

    user_id_regex          = re.compile(r"^@.+:.+")
    room_id_or_alias_regex = re.compile(r"^[#!].+:.+")
    http_s_url_regex       = re.compile(r"^https?://")

    lazy_load_filter: ClassVar[Dict[str, Any]] = {
        "room": {
            "ephemeral":    {"lazy_load_members": True},
            "state":        {"lazy_load_members": True},
            "timeline":     {"lazy_load_members": True},
            "account_data": {"lazy_load_members": True},
        },
    }

    low_limit_filter: ClassVar[Dict[str, Any]] = {
        "presence": {"limit": 1},

        "room": {
            "ephemeral": {"limit": 1},
            "timeline":  {
                "limit": 5,
                # This kind says another event was redacted, but we wouldn't
                # have it in our model, so nothing would be shown
                "not_types": ["m.room.redaction"],
            },
        },
    }

    no_profile_events_filter: ClassVar[Dict[str, Any]] = {
        "room": {
            "timeline": {"not_types": ["m.room.member"]},
        },
    }

    no_unknown_events_filter: ClassVar[Dict[str, Any]] = {
        "room": {
            "timeline": {
                "not_types": [
                    "m.room.message.feedback",
                    "m.room.pinned_events",
                    "m.call.*",
                    "m.room.third_party_invite",
                    "m.room.tombstone",
                    "m.reaction",
                ],
            },
        },
    }


    def __init__(self,
                 backend,
                 user:       str,
                 homeserver: str           = "https://matrix.org",
                 device_id:  Optional[str] = None) -> None:

        if not urlparse(homeserver).scheme:
            raise ValueError(
                f"homeserver is missing scheme (e.g. https://): {homeserver}",
            )

        store = Path(backend.appdirs.user_data_dir) / "encryption"
        store.mkdir(parents=True, exist_ok=True)

        super().__init__(
            homeserver = homeserver,
            user       = user,
            device_id  = device_id,
            store_path = store,
            config     = nio.AsyncClientConfig(
                max_timeout_retry_wait_time = 10,
                # TODO: pass a custom encryption DB pickle key?
            ),
        )

        self.backend:   "Backend"     = backend
        self.models:    ModelStore    = self.backend.models
        self.open_room: Optional[str] = None

        self.profile_task:       Optional[asyncio.Future] = None
        self.server_config_task: Optional[asyncio.Future] = None
        self.sync_task:          Optional[asyncio.Future] = None

        self.upload_monitors:    Dict[UUID, nio.TransferMonitor] = {}
        self.upload_tasks:       Dict[UUID, asyncio.Task]        = {}
        self.send_message_tasks: Dict[UUID, asyncio.Task]        = {}

        self.first_sync_done: asyncio.Event      = asyncio.Event()
        self.first_sync_date: Optional[datetime] = None

        self.past_tokens:          Dict[str, str] = {}     # {room_id: token}
        self.fully_loaded_rooms:   Set[str]       = set()  # {room_id}
        self.loaded_once_rooms:    Set[str]       = set()  # {room_id}
        self.cleared_events_rooms: Set[str]       = set()  # {room_id}

        self.nio_callbacks = NioCallbacks(self)


    def __repr__(self) -> str:
        return "%s(user_id=%r, homeserver=%r, device_id=%r)" % (
            type(self).__name__, self.user_id, self.homeserver, self.device_id,
        )


    async def _send(self, *args, **kwargs) -> nio.Response:
        """Raise a `MatrixError` subclass for any `nio.ErrorResponse`.

        This function is called by `nio.AsyncClient`'s methods to send
        requests to the server. Return normal responses, but catch any
        `ErrorResponse` to turn them into `MatrixError` exceptions we raise.
        """

        response = await super()._send(*args, **kwargs)

        if isinstance(response, nio.ErrorResponse):
            raise MatrixError.from_nio(response)

        return response


    @staticmethod
    def default_device_name() -> str:
        """Device name to set at login if the user hasn't set a custom one."""

        os_name = platform.system()

        if not os_name:  # unknown OS
            return __display_name__

        # On Linux, the kernel version is returned, so for a one-time-set
        # device name it would quickly be outdated.
        os_ver  = platform.release() if os_name == "Windows" else ""
        return f"{__display_name__} on {os_name} {os_ver}".rstrip()


    async def login(self, password: str, device_name: str = "") -> None:
        """Login to the server using the account's password."""

        await super().login(
            password, device_name or self.default_device_name(),
        )
        asyncio.ensure_future(self._start())


    async def resume(self, user_id: str, token: str, device_id: str) -> None:
        """Login to the server using an existing access token."""

        response = nio.LoginResponse(user_id, device_id, token)
        await self.receive_response(response)

        asyncio.ensure_future(self._start())


    async def logout(self) -> None:
        """Logout from the server. This will delete the device."""

        tasks = (self.profile_task, self.sync_task, self.server_config_task)

        for task in tasks:
            if task:
                task.cancel()
                with suppress(asyncio.CancelledError):
                    await task

        await super().logout()
        await self.close()


    @property
    def syncing(self) -> bool:
        """Return whether this client is currently syncing with the server."""

        if not self.sync_task:
            return False

        return not self.sync_task.done()


    async def _start(self) -> None:
        """Fetch our user profile, server config and enter the sync loop."""

        def on_profile_response(future) -> None:
            """Update our model `Account` with the received profile details."""

            if future.cancelled():  # Account logged out
                return

            exception = future.exception()

            if exception:
                log.warn("On %s client startup: %r", self.user_id, exception)
                self.profile_task = asyncio.ensure_future(
                    self.backend.get_profile(self.user_id),
                )
                self.profile_task.add_done_callback(on_profile_response)
                return

            resp                    = future.result()
            account                 = self.models["accounts"][self.user_id]
            account.profile_updated = datetime.now()
            account.display_name    = resp.displayname or ""
            account.avatar_url      = resp.avatar_url or ""

        def on_server_config_response(future) -> None:
            """Update our model `Account` with the received config details."""

            if future.cancelled():  # Account logged out
                return

            exception = future.exception()

            if exception:
                log.warn("On %s client startup: %r", self.user_id, exception)
                self.server_config_task = asyncio.ensure_future(
                    self.get_server_config(),
                )
                self.server_config_task.add_done_callback(
                    on_server_config_response,
                )
                return

            account                 = self.models["accounts"][self.user_id]
            account.max_upload_size = future.result()

        self.profile_task = asyncio.ensure_future(
            self.backend.get_profile(self.user_id),
        )
        self.profile_task.add_done_callback(on_profile_response)

        self.server_config_task = asyncio.ensure_future(
            self.get_server_config(),
        )
        self.server_config_task.add_done_callback(on_server_config_response)

        filter1 = deepcopy(self.lazy_load_filter)
        utils.dict_update_recursive(filter1, self.low_limit_filter)

        cfg = self.backend.ui_settings
        if cfg["hideProfileChangeEvents"] or cfg["hideMembershipEvents"]:
            utils.dict_update_recursive(filter1, self.no_profile_events_filter)

        if cfg["hideUnknownEvents"]:
            filter1["room"]["timeline"]["not_types"].extend(
                self.no_unknown_events_filter["room"]["timeline"]["not_types"],
            )

        while True:
            try:
                self.sync_task = asyncio.ensure_future(self.sync_forever(
                    timeout           = 10_000,
                    sync_filter       = self.lazy_load_filter,
                    first_sync_filter = filter1,
                ))
                await self.sync_task
                break  # task cancelled
            except Exception as err:
                trace = traceback.format_exc().rstrip()

                if isinstance(err, MatrixError) and err.http_code >= 500:
                    log.warning(
                        "Server failure during sync for %s:\n%s",
                        self.user_id,
                        trace,
                    )
                else:
                    LoopException(str(err), err, trace)

                await asyncio.sleep(2)


    async def get_server_config(self) -> int:
        """Return the maximum upload size on this server"""
        return (await self.content_repository_config()).upload_size


    async def can_kick(self, room_id: str, target_user_id: str) -> bool:
        """Return whether we can kick a certain user in a room."""

        levels = self.all_rooms[room_id].power_levels
        return levels.can_user_kick(self.user_id, target_user_id)


    async def can_ban(self, room_id: str, target_user_id: str) -> bool:
        """Return whether we can ban/unbun a certain user in a room."""

        levels = self.all_rooms[room_id].power_levels
        return levels.can_user_ban(self.user_id, target_user_id)


    @property
    def all_rooms(self) -> Dict[str, nio.MatrixRoom]:
        """Return dict containing both our joined and invited rooms."""

        return {**self.invited_rooms, **self.rooms}


    async def send_text(self, room_id: str, text: str) -> None:
        """Send a markdown `m.text` or `m.notice` (with `/me`) message ."""

        from_md = partial(HTML.from_markdown, room_id=room_id)

        escape = False
        if text.startswith("//") or text.startswith(r"\/"):
            escape = True
            text   = text[1:]

        if text.startswith("/me ") and not escape:
            event_type = nio.RoomMessageEmote
            text       = text[len("/me "): ]
            content    = {"body": text, "msgtype": "m.emote"}
            to_html    = from_md(text, inline=True, outgoing=True)
            echo_body  = from_md(text, inline=True)
        else:
            event_type = nio.RoomMessageText
            content    = {"body": text, "msgtype": "m.text"}
            to_html    = from_md(text, outgoing=True)
            echo_body  = from_md(text)

        if to_html not in (html.escape(text), f"<p>{html.escape(text)}</p>"):
            content["format"]         = "org.matrix.custom.html"
            content["formatted_body"] = to_html

        # Can't use the standard Matrix transaction IDs; they're only visible
        # to the sender so our other accounts wouldn't be able to replace
        # local echoes by real messages.
        tx_id = uuid4()
        content[f"{__app_name__}.transaction_id"] = str(tx_id)

        mentions = HTML.mentions_in_html(echo_body)
        await self._local_echo(
            room_id, tx_id, event_type, content=echo_body, mentions=mentions,
        )

        await self._send_message(room_id, content, tx_id)


    async def toggle_pause_upload(
        self, room_id: str, uuid: Union[str, UUID],
    ) -> None:
        if isinstance(uuid, str):
            uuid = UUID(uuid)

        pause = not self.upload_monitors[uuid].pause

        self.upload_monitors[uuid].pause                  = pause
        self.models[room_id, "uploads"][str(uuid)].paused = pause


    async def cancel_upload(self, uuid: Union[str, UUID]) -> None:
        if isinstance(uuid, str):
            uuid = UUID(uuid)

        self.upload_tasks[uuid].cancel()


    async def send_file(self, room_id: str, path: Union[Path, str]) -> None:
        """Send a `m.file`, `m.image`, `m.audio` or `m.video` message."""

        item_uuid = uuid4()

        try:
            await self._send_file(item_uuid, room_id, path)
        except (nio.TransferCancelledError, asyncio.CancelledError):
            log.info("Deleting item for cancelled upload %s", item_uuid)
            del self.upload_monitors[item_uuid]
            del self.upload_tasks[item_uuid]
            del self.models[room_id, "uploads"][str(item_uuid)]


    async def _send_file(
        self, item_uuid: UUID, room_id: str, path: Union[Path, str],
    ) -> None:
        """Upload and monitor a file + thumbnail and send the built event."""

        # TODO: this function is way too complex, and most of it should be
        # refactored into nio.

        transaction_id = uuid4()
        path           = Path(path)
        encrypt        = room_id in self.encrypted_rooms

        try:
            size = path.resolve().stat().st_size
        except (PermissionError, FileNotFoundError):
            # This error will be caught again by the try block later below
            size = 0

        monitor     = nio.TransferMonitor(size)
        upload_item = Upload(item_uuid, path, total_size=size)

        self.models[room_id, "uploads"][str(item_uuid)] = upload_item

        self.upload_monitors[item_uuid] = monitor
        self.upload_tasks[item_uuid]    = current_task()  # type: ignore

        def on_transferred(transferred: int) -> None:
            upload_item.uploaded  = transferred

        def on_speed_changed(speed: float) -> None:
            upload_item.speed     = speed
            upload_item.time_left = monitor.remaining_time or timedelta(0)

        monitor.on_transferred   = on_transferred
        monitor.on_speed_changed = on_speed_changed

        try:
            url, mime, crypt_dict = await self.upload(
                lambda *_: path,
                filename = path.name,
                filesize = size,
                encrypt  = encrypt,
                monitor  = monitor,
            )

            # FIXME: nio might not catch the cancel in time
            if monitor.cancel:
                raise nio.TransferCancelledError()

        except (MatrixError, OSError) as err:
            upload_item.status     = UploadStatus.Error
            upload_item.error      = type(err)
            upload_item.error_args = err.args

            # Wait for cancellation from UI, see parent send_file() method
            while True:
                await asyncio.sleep(0.1)

        upload_item.status = UploadStatus.Caching
        await Media.from_existing_file(self.backend.media_cache, url, path)

        kind = (mime or "").split("/")[0]

        thumb_url:  str                       = ""
        thumb_info: Optional[MatrixImageInfo] = None

        content: dict = {
            f"{__app_name__}.transaction_id": str(transaction_id),

            "body": path.name,
            "info": {
                "mimetype": mime,
                "size":     upload_item.total_size,
            },
        }

        if encrypt:
            content["file"] = {"url": url, **crypt_dict}
        else:
            content["url"] = url

        if kind == "image":
            is_svg = mime == "image/svg+xml"

            event_type = \
                nio.RoomEncryptedImage if encrypt else nio.RoomMessageImage

            content["msgtype"] = "m.image"

            content["info"]["w"], content["info"]["h"] = (
                await utils.svg_dimensions(path) if is_svg else
                PILImage.open(path).size
            )

            try:
                thumb_data, thumb_info = await self.generate_thumbnail(
                    path, is_svg=is_svg,
                )
            except UneededThumbnail:
                pass
            except Exception:
                trace = traceback.format_exc().rstrip()
                log.warning("Failed thumbnailing %s:\n%s", path, trace)
            else:
                thumb_ext  = "png" if thumb_info.mime == "image/png" else "jpg"
                thumb_name = f"{path.stem}_thumbnail.{thumb_ext}"

                upload_item.status     = UploadStatus.Uploading
                upload_item.filepath   = Path(thumb_name)
                upload_item.total_size = len(thumb_data)

                try:
                    upload_item.total_size = thumb_info.size

                    monitor = nio.TransferMonitor(thumb_info.size)
                    monitor.on_transferred = on_transferred
                    monitor.on_speed_changed = on_speed_changed

                    self.upload_monitors[item_uuid] = monitor

                    thumb_url, _, thumb_crypt_dict = await self.upload(
                        lambda *_: thumb_data,
                        filename = f"{path.stem}_sample{path.suffix}",
                        filesize = thumb_info.size,
                        encrypt  = encrypt,
                        monitor  = monitor,
                    )

                    # FIXME: nio might not catch the cancel in time
                    if monitor.cancel:
                        raise nio.TransferCancelledError()
                except MatrixError as err:
                    log.warning(f"Failed uploading thumbnail {path}: {err}")
                else:
                    upload_item.status = UploadStatus.Caching

                    await Thumbnail.from_bytes(
                        self.backend.media_cache,
                        thumb_url,
                        path.name,
                        thumb_data,
                        wanted_size = (content["info"]["w"],
                                       content["info"]["h"]),
                    )

                    if encrypt:
                        content["info"]["thumbnail_file"]  = {
                            "url": thumb_url,
                            **thumb_crypt_dict,
                        }
                    else:
                        content["info"]["thumbnail_url"]  = thumb_url

                    content["info"]["thumbnail_info"] = thumb_info.as_dict()

        elif kind == "audio":
            event_type = \
                nio.RoomEncryptedAudio if encrypt else nio.RoomMessageAudio

            content["msgtype"]          = "m.audio"
            content["info"]["duration"] = getattr(
                MediaInfo.parse(path).tracks[0], "duration", 0,
            ) or 0

        elif kind == "video":
            event_type = \
                nio.RoomEncryptedVideo if encrypt else nio.RoomMessageVideo

            content["msgtype"] = "m.video"

            tracks = MediaInfo.parse(path).tracks

            content["info"]["duration"] = \
                getattr(tracks[0], "duration", 0) or 0

            content["info"]["w"] = max(
                getattr(t, "width", 0) or 0 for t in tracks
            )
            content["info"]["h"] = max(
                getattr(t, "height", 0) or 0 for t in tracks
            )

        else:
            event_type = \
                nio.RoomEncryptedFile if encrypt else nio.RoomMessageFile

            content["msgtype"]  = "m.file"
            content["filename"] = path.name

        del self.upload_monitors[item_uuid]
        del self.upload_tasks[item_uuid]
        del self.models[room_id, "uploads"][str(upload_item.id)]

        await self._local_echo(
            room_id,
            transaction_id,
            event_type,
            inline_content   = path.name,
            media_url        = url,
            media_title      = path.name,
            media_width      = content["info"].get("w", 0),
            media_height     = content["info"].get("h", 0),
            media_duration   = content["info"].get("duration", 0),
            media_size       = content["info"]["size"],
            media_mime       = content["info"]["mimetype"],
            thumbnail_url    = thumb_url,
            thumbnail_width  =
                content["info"].get("thumbnail_info", {}).get("w", 0),
            thumbnail_height =
                content["info"].get("thumbnail_info", {}).get("h", 0),
            thumbnail_mime =
                content["info"].get("thumbnail_info", {}).get("mimetype", ""),
        )

        await self._send_message(room_id, content, transaction_id)


    async def _local_echo(
        self,
        room_id:        str,
        transaction_id: UUID,
        event_type:     Type[nio.Event],
        **event_fields,
    ) -> None:
        """Register a local model `Event` while waiting for the server.

        When the user sends a message, we want to show instant feedback in
        the UI timeline without waiting for the servers to receive our message
        and retransmit it to us.

        The event will be locally echoed for all our accounts that are members
        of the `room_id` room.
        This allows sending messages from other accounts within the same
        composer without having to go to another page in the UI,
        and getting direct feedback for these accounts in the timeline.

        When we do get the real event retransmited by the server, it will
        replace the local one we registered.
        """

        our_info = self.models[self.user_id, room_id, "members"][self.user_id]

        content = event_fields.get("content", "").strip()

        if content and "inline_content" not in event_fields:
            event_fields["inline_content"] = HTML.filter(
                content, inline=True, room_id=room_id,
            )

        event = Event(
            id            = f"echo-{transaction_id}",
            event_id      = "",
            event_type    = event_type,
            date          = datetime.now(),
            sender_id     = self.user_id,
            sender_name   = our_info.display_name,
            sender_avatar = our_info.avatar_url,
            is_local_echo = True,
            links         = Event.parse_links(content),
            **event_fields,
        )

        for user_id in self.models["accounts"]:
            if user_id in self.models[self.user_id, room_id, "members"]:
                key = f"echo-{transaction_id}"
                self.models[user_id, room_id, "events"][key] = deepcopy(event)

        await self.set_room_last_event(room_id, event)


    async def _send_message(
        self, room_id: str, content: dict, transaction_id: UUID,
    ) -> None:
        """Send a message event with `content` dict to a room."""

        self.send_message_tasks[transaction_id] = \
            current_task()  # type: ignore

        async with self.backend.send_locks[room_id]:
            await self.room_send(
                room_id                   = room_id,
                message_type              = "m.room.message",
                content                   = content,
                ignore_unverified_devices = True,
            )


    async def load_all_room_members(self, room_id: str) -> None:
        """Request a room's full member list if it hasn't already been loaded.

        Member lazy-loading is used to accelerate the initial sync with the
        server. This method will be called from QML to load a room's entire
        member list when the user is currently viewing the room.
        """

        room = self.all_rooms[room_id]

        if not room.members_synced:
            await super().joined_members(room_id)
            await self.register_nio_room(self.all_rooms[room_id])


    async def load_past_events(self, room_id: str) -> bool:
        """Ask the server for 100 previous events of the room.

        Events from before the client was started will be requested and
        registered into our models.

        Returns whether there are any messages left to load.
        """

        if room_id in self.fully_loaded_rooms or \
           room_id in self.invited_rooms or \
           room_id in self.cleared_events_rooms or \
           self.models[self.user_id, "rooms"][room_id].left:
            return False

        await self.first_sync_done.wait()

        while not self.past_tokens.get(room_id):
            # If a new room was added, wait for onSyncResponse to set the token
            await asyncio.sleep(0.1)

        response = await self.room_messages(
            room_id        = room_id,
            start          = self.past_tokens[room_id],
            limit          = 100 if room_id in self.loaded_once_rooms else 20,
            message_filter = self.lazy_load_filter,
        )

        self.loaded_once_rooms.add(room_id)
        more_to_load = True

        self.past_tokens[room_id] = response.end

        for event in response.chunk:
            if isinstance(event, nio.RoomCreateEvent):
                self.fully_loaded_rooms.add(room_id)
                more_to_load = False

            for cb in self.event_callbacks:
                if (cb.filter is None or isinstance(event, cb.filter)):
                    await cb.func(self.all_rooms[room_id], event)

        return more_to_load


    async def new_direct_chat(self, invite: str, encrypt: bool = False) -> str:
        """Create a room and invite a single user in it for a direct chat."""

        if invite == self.user_id:
            raise InvalidUserInContext(invite)

        if not self.user_id_regex.match(invite):
            raise InvalidUserId(invite)

        # Raise MatrixNotFound if profile doesn't exist
        await self.get_profile(invite)

        response = await super().room_create(
            invite        = [invite],
            is_direct     = True,
            visibility    = nio.RoomVisibility.private,
            initial_state =
                [nio.EnableEncryptionBuilder().as_dict()] if encrypt else [],
        )
        return response.room_id


    async def new_group_chat(
        self,
        name:     Optional[str] = None,
        topic:    Optional[str] = None,
        public:   bool          = False,
        encrypt:  bool          = False,
        federate: bool          = True,
    ) -> str:
        """Create a new matrix room with the purpose of being a group chat."""

        response = await super().room_create(
            name       = name or None,
            topic      = topic or None,
            federate   = federate,
            visibility =
                nio.RoomVisibility.public if public else
                nio.RoomVisibility.private,
            initial_state =
                [nio.EnableEncryptionBuilder().as_dict()] if encrypt else [],
        )
        return response.room_id

    async def room_join(self, alias_or_id_or_url: str) -> str:
        """Join an existing matrix room."""

        string = alias_or_id_or_url.strip()

        if self.http_s_url_regex.match(string):
            for part in urlparse(string).fragment.split("/"):
                if self.room_id_or_alias_regex.match(part):
                    string = part
                    break
            else:
                raise ValueError(f"No alias or room id found in url {string}")

        if not self.room_id_or_alias_regex.match(string):
            raise ValueError("Not an alias or room id")

        response = await super().join(string)
        return response.room_id


    async def room_forget(self, room_id: str) -> None:
        """Leave a joined room (or decline an invite) and forget its history.

        If all the members of a room leave and forget it, that room
        will be marked as suitable for destruction by the server.
        """

        self.models[self.user_id, "rooms"].pop(room_id, None)
        self.models.pop((self.user_id, room_id, "events"), None)
        self.models.pop((self.user_id, room_id, "members"), None)

        try:
            await super().room_leave(room_id)
        except MatrixNotFound:  # already left
            pass

        await super().room_forget(room_id)

    async def room_mass_invite(
        self, room_id: str, *user_ids: str,
    ) -> Tuple[List[str], List[Tuple[str, Exception]]]:
        """Invite users to a room in parallel.

        Returns a tuple with:

        - A list of users we successfully invited
        - A list of `(user_id, Exception)` tuples for those failed to invite.
        """

        user_ids = tuple(
            uid for uid in user_ids
            # Server would return a 403 forbidden for users already in the room
            if uid not in self.all_rooms[room_id].users
        )

        async def invite(user_id: str):
            if not self.user_id_regex.match(user_id):
                return InvalidUserId(user_id)

            if not self.rooms[room_id].federate:
                _, user_server = user_id.split(":", maxsplit=1)
                _, room_server = room_id.split(":", maxsplit=1)

                user_server = re.sub(r":443$", "", user_server)
                room_server = re.sub(r":443$", "", room_server)

                if user_server != room_server:
                    return UserFromOtherServerDisallowed(user_id)

            try:
                await self.get_profile(user_id)
            except MatrixNotFound as err:
                return err

            return await self.room_invite(room_id, user_id)

        coros        = [invite(uid) for uid in user_ids]
        successes    = []
        errors: list = []
        responses    = await asyncio.gather(*coros)

        for user_id, response in zip(user_ids, responses):
            if isinstance(response, nio.RoomInviteError):
                errors.append((user_id, MatrixError.from_nio(response)))

            elif isinstance(response, Exception):
                errors.append((user_id, response))

            else:
                successes.append(user_id)

        return (successes, errors)


    async def get_redacted_event_content(
        self,
        nio_type: Type[nio.Event],
        redacter: str,
        sender:   str,
        reason:   str = "",
    ) -> str:
        """Get content to be displayed in place of a redacted event."""

        kind = (
            "message" if issubclass(nio_type, nio.RoomMessage) else
            "media" if issubclass(nio_type, nio.RoomMessageMedia) else
            "event"
        )

        content = f"%1 removed this {kind}" if redacter == sender else \
                  f"%1's {kind} was removed by %2"

        if reason:
            content = f"{content}, reason: {reason}"

        return content


    async def room_mass_redact(
        self, room_id: str, reason: str, *event_client_ids: str,
    ) -> List[nio.RoomRedactResponse]:
        """Redact events from a room in parallel."""

        tasks = []

        for user_id in self.backend.clients:
            for client_id in event_client_ids:

                event = self.models[user_id, room_id, "events"].get(client_id)

                if not event:
                    continue

                if event.is_local_echo:
                    if user_id == self.user_id:
                        uuid = UUID(event.id.replace("echo-", ""))
                        self.send_message_tasks[uuid].cancel()

                    event.is_local_echo = False
                else:
                    if user_id == self.user_id:
                        tasks.append(
                            self.room_redact(room_id, event.event_id, reason),
                        )

                    event.is_local_echo = True

                event.content = await self.get_redacted_event_content(
                    event.event_type, self.user_id, event.sender_id, reason,
                )

                event.event_type = nio.RedactedEvent

        return await asyncio.gather(*tasks)


    async def generate_thumbnail(
        self, data: UploadData, is_svg: bool = False,
    ) -> Tuple[bytes, MatrixImageInfo]:
        """Create a thumbnail from an image, return the bytes and info."""

        png_modes = ("1", "L", "P", "RGBA")

        data   = b"".join([c async for c in async_generator_from_data(data)])
        is_svg = await utils.guess_mime(data) == "image/svg+xml"

        if is_svg:
            svg_width, svg_height = await utils.svg_dimensions(data)

            data = cairosvg.svg2png(
                bytestring    = data,
                parent_width  = svg_width,
                parent_height = svg_height,
            )

        thumb = PILImage.open(io.BytesIO(data))

        small       = thumb.width <= 800 and thumb.height <= 600
        is_jpg_png  = thumb.format in ("JPEG", "PNG")
        jpgable_png = thumb.format == "PNG" and thumb.mode not in png_modes

        if small and is_jpg_png and not jpgable_png and not is_svg:
            raise UneededThumbnail()

        if not small:
            thumb.thumbnail((800, 600))

        with io.BytesIO() as out:
            if thumb.mode in png_modes:
                thumb.save(out, "PNG", optimize=True)
                mime = "image/png"
            else:
                thumb.convert("RGB").save(out, "JPEG", optimize=True)
                mime = "image/jpeg"

            thumb_data = out.getvalue()
            thumb_size = len(thumb_data)

        if thumb_size >= len(data) and is_jpg_png and not is_svg:
            raise UneededThumbnail()

        info = MatrixImageInfo(thumb.width, thumb.height, mime, thumb_size)
        return (thumb_data, info)


    async def upload(
        self,
        data_provider: nio.DataProvider,
        filename:      Optional[str]                 = None,
        filesize:      Optional[int]                 = None,
        mime:          Optional[str]                 = None,
        encrypt:       bool                          = False,
        monitor:       Optional[nio.TransferMonitor] = None,
    ) -> UploadReturn:
        """Upload a file to the matrix homeserver."""

        if filesize > self.models["accounts"][self.user_id].max_upload_size:
            raise MatrixTooLarge()

        mime = mime or await utils.guess_mime(data_provider(0, 0))

        response, decryption_dict = await super().upload(
            data_provider,
            "application/octet-stream" if encrypt else mime,
            filename,
            encrypt,
            monitor,
            filesize,
        )

        return UploadReturn(response.content_uri, mime, decryption_dict)


    async def set_avatar_from_file(self, path: Union[Path, str]) -> None:
        """Upload an image to the homeserver and set it as our avatar."""

        path = Path(path)
        mime = await utils.guess_mime(path)

        if mime.split("/")[0] != "image":
            raise BadMimeType(wanted="image/*", got=mime)

        mxc, *_ = await self.upload(
            data_provider = lambda *_: path,
            filename      = path.name,
            filesize      = path.resolve().stat().st_size,
            mime          = mime,
        )
        await self.set_avatar(mxc)


    async def import_keys(self, infile: str, passphrase: str) -> None:
        """Import decryption keys from a file, then retry decrypting events."""

        await super().import_keys(infile, passphrase)
        await self.retry_decrypting_events()


    async def export_keys(self, outfile: str, passphrase: str) -> None:
        """Export our decryption keys to a file."""

        path = Path(outfile)
        path.parent.mkdir(parents=True, exist_ok=True)

        # The QML dialog asks the user if he wants to overwrite before this
        if path.exists():
            path.unlink()

        await super().export_keys(outfile, passphrase)


    async def retry_decrypting_events(self) -> None:
        """Retry decrypting room `Event`s in our model we failed to decrypt."""

        for sync_id, model in self.models.items():
            if not (isinstance(sync_id, tuple) and
                    len(sync_id) == 3 and
                    sync_id[0] == self.user_id and
                    sync_id[2] == "events"):
                continue

            _, room_id, _ = sync_id

            for ev in deepcopy(model).values():
                room = self.all_rooms[room_id]

                if isinstance(ev.source, nio.MegolmEvent):
                    try:
                        decrypted = self.decrypt_event(ev.source)

                        if not decrypted:
                            raise nio.EncryptionError()

                    except nio.EncryptionError:
                        continue

                    for cb in self.event_callbacks:
                        if not cb.filter or isinstance(decrypted, cb.filter):
                            await asyncio.coroutine(cb.func)(room, decrypted)


    async def clear_events(self, room_id: str) -> None:
        """Remove every `Event` of a room we registered in our model.

        The events will be gone from the UI, until the client is restarted.
        """

        self.cleared_events_rooms.add(room_id)

        model = self.models[self.user_id, room_id, "events"]
        if model:
            model.clear()

        self.models[self.user_id, "rooms"][room_id].last_event_date = \
            ZeroDate

    # Functions to register data into models

    async def event_is_past(self, ev: Union[nio.Event, Event]) -> bool:
        """Return whether an event was created before this client started."""

        if not self.first_sync_date:
            return True

        if isinstance(ev, Event):
            return ev.date < self.first_sync_date

        date = datetime.fromtimestamp(ev.server_timestamp / 1000)
        return date < self.first_sync_date


    async def set_room_last_event(self, room_id: str, item: Event) -> None:
        """Set the `last_event` for a `Room` using data in our `Event` model.

        The `last_event` is notably displayed in the UI room subtitles.
        """

        room = self.models[self.user_id, "rooms"][room_id]

        if item.date > room.last_event_date:
            room.last_event_date = item.date


    async def register_nio_room(
        self, room: nio.MatrixRoom, left: bool = False,
    ) -> None:
        """Register a `nio.MatrixRoom` as a `Room` object in our model."""

        # Add room
        inviter        = getattr(room, "inviter", "") or ""
        levels         = room.power_levels
        can_send_state = partial(levels.can_user_send_state, self.user_id)
        can_send_msg   = partial(levels.can_user_send_message, self.user_id)

        try:
            registered      = self.models[self.user_id, "rooms"][room.room_id]
            last_event_date = registered.last_event_date
            typing_members  = registered.typing_members
            mentions        = registered.mentions
            unreads         = registered.unreads
        except KeyError:
            last_event_date = datetime.fromtimestamp(0)
            typing_members  = []
            mentions        = 0
            unreads         = 0

        self.models[self.user_id, "rooms"][room.room_id] = Room(
            id             = room.room_id,
            given_name     = room.name or "",
            display_name   = room.display_name or "",
            avatar_url     = room.gen_avatar_url or "",
            plain_topic    = room.topic or "",
            topic          = HTML.filter(
                room.topic or "", inline=True, room_id=room.room_id,
            ),
            inviter_id     = inviter,
            inviter_name   = room.user_name(inviter) if inviter else "",
            inviter_avatar =
                (room.avatar_url(inviter) or "") if inviter else "",
            left           = left,

            typing_members = typing_members,

            encrypted       = room.encrypted,
            invite_required = room.join_rule == "invite",
            guests_allowed  = room.guest_access == "can_join",

            can_invite           = levels.can_user_invite(self.user),
            can_kick             = levels.can_user_kick(self.user),
            can_redact_all       = levels.can_user_redact(self.user),
            can_send_messages    = can_send_msg(),
            can_set_name         = can_send_state("m.room.name"),
            can_set_topic        = can_send_state("m.room.topic"),
            can_set_avatar       = can_send_state("m.room.avatar"),
            can_set_encryption   = can_send_state("m.room.encryption"),
            can_set_join_rules   = can_send_state("m.room.join_rules"),
            can_set_guest_access = can_send_state("m.room.guest_access"),

            last_event_date = last_event_date,
            mentions        = mentions,
            unreads         = unreads,

        )

        # List members that left the room, then remove them from our model
        left_the_room = [
            user_id
            for user_id in self.models[self.user_id, room.room_id, "members"]
            if user_id not in room.users
        ]

        for user_id in left_the_room:
            del self.models[self.user_id, room.room_id, "members"][user_id]
            HTML.rooms_user_id_names[room.room_id].pop(user_id, None)

        # Add the room members to the added room
        new_dict = {
            user_id: Member(
                id           = user_id,
                display_name = room.user_name(user_id)  # disambiguated
                               if member.display_name else "",
                avatar_url   = member.avatar_url or "",
                typing       = user_id in room.typing_users,
                power_level  = member.power_level,
                invited      = member.invited,
            ) for user_id, member in room.users.items()
        }
        self.models[self.user_id, room.room_id, "members"].update(new_dict)

        for user_id, member in room.users.items():
            if member.display_name:
                HTML.rooms_user_id_names[room.room_id][user_id] = \
                    member.display_name


    async def get_member_name_avatar(
        self, room_id: str, user_id: str,
    ) -> Tuple[str, str]:
        """Return a room member's display name and avatar.

        If the member isn't found in the room (e.g. they left), their
        profile is retrieved using `MatrixClient.backend.get_profile()`.
        """

        try:
            item = self.models[self.user_id, room_id, "members"][user_id]

        except KeyError:  # e.g. user is not anymore in the room
            try:
                info = await self.backend.get_profile(user_id)
                return (info.displayname or "", info.avatar_url or "")

            except MatrixError:
                return ("", "")

        else:
            return (item.display_name, item.avatar_url)


    async def register_nio_event(
        self,
        room:     nio.MatrixRoom,
        ev:       nio.Event,
        event_id: str = "",
        **fields,
    ) -> None:
        """Register a `nio.Event` as a `Event` object in our model."""

        await self.register_nio_room(room)

        sender_name, sender_avatar = \
            await self.get_member_name_avatar(room.room_id, ev.sender)

        target_id = getattr(ev, "state_key", "") or ""

        target_name, target_avatar = \
            await self.get_member_name_avatar(room.room_id, target_id) \
            if target_id else ("", "")

        content = fields.get("content", "").strip()

        if content and "inline_content" not in fields:
            fields["inline_content"] = HTML.filter(
                content, inline=True, room_id=room.room_id,
            )

        # Create Event ModelItem

        item = Event(
            id            = event_id or ev.event_id,
            event_id      = ev.event_id,
            event_type    = type(ev),
            source        = ev,
            date          = datetime.fromtimestamp(ev.server_timestamp / 1000),
            sender_id     = ev.sender,
            sender_name   = sender_name,
            sender_avatar = sender_avatar,
            target_id     = target_id,
            target_name   = target_name,
            target_avatar = target_avatar,
            links         = Event.parse_links(content),
            **fields,
        )

        # Add the Event to model

        model = self.models[self.user_id, room.room_id, "events"]

        tx_id = ev.source.get("content", {}).get(
            f"{__app_name__}.transaction_id",
        )
        from_us = ev.sender in self.backend.clients

        if from_us and tx_id and f"echo-{tx_id}" in model:
            item.id = f"echo-{tx_id}"

        model[item.id] = item
        await self.set_room_last_event(room.room_id, item)

        # Alerts

        if from_us or await self.event_is_past(ev):
            return

        AlertRequested()

        if self.open_room != room.room_id:
            room          = self.models[self.user_id, "rooms"][room.room_id]
            room.unreads += 1

            content = fields.get("content", "")

            if HTML.user_id_link_in_html(content, self.user_id):
                room.mentions += 1
