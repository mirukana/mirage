# SPDX-License-Identifier: LGPL-3.0-or-later

"""Matrix client to interact with a homeserver and other related classes."""

import asyncio
import html
import io
import logging as log
import platform
import re
import sys
import textwrap
import traceback
from contextlib import suppress
from copy import deepcopy
from datetime import datetime, timedelta
from functools import partial
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import (
    TYPE_CHECKING, Any, Callable, ClassVar, Coroutine, Dict, List, NamedTuple,
    Optional, Set, Tuple, Type, Union,
)
from urllib.parse import urlparse
from uuid import UUID, uuid4

import aiofiles
import cairosvg
from PIL import Image as PILImage
from pymediainfo import MediaInfo

import nio
from nio.crypto import AsyncDataT as UploadData
from nio.crypto import async_generator_from_data

from . import __app_name__, __display_name__, utils
from .errors import (
    BadMimeType, InvalidUserId, InvalidUserInContext, MatrixBadGateway,
    MatrixError, MatrixForbidden, MatrixNotFound, MatrixTooLarge,
    MatrixUnauthorized, UneededThumbnail, UserFromOtherServerDisallowed,
)
from .html_markdown import HTML_PROCESSOR as HTML
from .media_cache import Media, Thumbnail
from .models.items import (
    ZERO_DATE, Account, Event, Member, Room, Upload, UploadStatus,
)
from .models.model_store import ModelStore
from .nio_callbacks import NioCallbacks
from .presence import Presence
from .pyotherside_events import AlertRequested, LoopException

if TYPE_CHECKING:
    from .backend import Backend

if sys.version_info >= (3, 7):
    current_task = asyncio.current_task
else:
    current_task = asyncio.Task.current_task

CryptDict    = Dict[str, Any]
PathCallable = Union[
    str, Path, Callable[[], Coroutine[None, None, Union[str, Path]]],
]

REPLY_FALLBACK = (
"<mx-reply>"
    "<blockquote>"
        '<a href="https://matrix.to/#/{room_id}/{event_id}">In reply to</a> '
        '<a href="https://matrix.to/#/{user_id}">{user_id}</a>'
        "<br>"
        "{content}"
    "</blockquote>"
"</mx-reply>"
"{reply_content}"
)


class SyncFilterIds(NamedTuple):
    """Uploaded filter IDs for various API."""

    first:  str
    others: str

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


    def __init__(
        self,
         backend,
         user:       str           = "",
         homeserver: str           = "https://matrix.org",
         device_id:  Optional[str] = None,
    ) -> None:

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

        self.backend: "Backend"  = backend
        self.models:  ModelStore = self.backend.models

        self.profile_task:       Optional[asyncio.Future] = None
        self.server_config_task: Optional[asyncio.Future] = None
        self.sync_task:          Optional[asyncio.Future] = None
        self.start_task:         Optional[asyncio.Future] = None

        self.upload_monitors:    Dict[UUID, nio.TransferMonitor] = {}
        self.upload_tasks:       Dict[UUID, asyncio.Task]        = {}
        self.send_message_tasks: Dict[UUID, asyncio.Task]        = {}

        self._presence:             str                     = ""
        self._sync_filter_ids:      Optional[SyncFilterIds] = None
        self._sync_filter_ids_lock: asyncio.Lock            = asyncio.Lock()
        self.first_sync_done:       asyncio.Event           = asyncio.Event()
        self.first_sync_date:       Optional[datetime]      = None
        self.last_sync_error:       Optional[Exception]     = None

        self.past_tokens:          Dict[str, str] = {}     # {room_id: token}
        self.fully_loaded_rooms:   Set[str]       = set()  # {room_id}
        self.loaded_once_rooms:    Set[str]       = set()  # {room_id}
        self.cleared_events_rooms: Set[str]       = set()  # {room_id}

        # {room_id: event}
        self.power_level_events: Dict[str, nio.PowerLevelsEvent] = {}

        self.nio_callbacks = NioCallbacks(self)


    def __repr__(self) -> str:
        return "%s(user_id=%r, homeserver=%r, device_id=%r)" % (
            type(self).__name__, self.user_id, self.homeserver, self.device_id,
        )


    @property
    def healthy(self) -> bool:
        """Return whether we're syncing and last sync was successful."""

        task = self.sync_task

        if not task or not self.first_sync_date or self.last_sync_error:
            return False

        return not task.done()


    @property
    def default_device_name(self) -> str:
        """Device name to set at login if the user hasn't set a custom one."""

        os_name = platform.system()

        if not os_name:  # unknown OS
            return __display_name__

        # On Linux, the kernel version is returned, so for a one-time-set
        # device name it would quickly be outdated.
        os_ver  = platform.release() if os_name == "Windows" else ""
        return f"{__display_name__} on {os_name} {os_ver}".rstrip()


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


    async def login(
        self, password: Optional[str] = None, token: Optional[str] = None,
    ) -> None:
        """Login to server using `m.login.password` or `m.login.token` flows.

        Login can be done with the account's password (if the server supports
        this flow) OR a token obtainable through various means.

        One of the way to obtain a token is to follow the `m.login.sso` flow
        first, see `Backend.start_sso_auth()` & `Backend.continue_sso_auth()`.
        """

        await super().login(password, self.default_device_name, token)

        order          = 0
        saved_accounts = await self.backend.saved_accounts.read()

        if saved_accounts:
            order = max(
                account.get("order", i)
                for i, account in enumerate(saved_accounts.values())
            ) + 1

        # We need to create account model item here, because _start() needs it
        item = self.models["accounts"].setdefault(
            self.user_id, Account(self.user_id, order),
        )

        # TODO: be abke to set presence before logging in
        item.set_fields(presence=Presence.State.online, connecting=True)
        self._presence  = "online"
        self.start_task = asyncio.ensure_future(self._start())


    async def resume(
        self,
        user_id:      str,
        access_token: str,
        device_id:    str,
        state:        str = "online",
        status_msg:   str = "",
    ) -> None:
        """Restore a previous login to the server with a saved access token."""

        self.restore_login(user_id, device_id, access_token)

        account        = self.models["accounts"][user_id]
        self._presence = "offline" if state == "invisible" else state

        account.set_fields(
            presence=Presence.State(state), status_msg=status_msg,
        )

        if state != "offline":
            account.connecting = True
            self.start_task    = asyncio.ensure_future(self._start())


    async def logout(self) -> None:
        """Logout from the server. This will delete the device."""

        await self._stop()
        await super().logout()
        await self.close()


    async def terminate(self) -> None:
        """Stop tasks, Set our presence offline and close HTTP connections."""

        await self._stop()

        if self._presence != "offline":
            try:
                await asyncio.wait_for(
                    self.set_presence("offline", save=False),
                    timeout = 10,
                )
            except asyncio.TimeoutError:
                log.warn("%s timed out", self.user_id)

        await self.close()


    async def _start(self) -> None:
        """Fetch our user profile, server config and enter the sync loop."""

        def on_server_config_response(future) -> None:
            """Update our model `Account` with the received config details."""

            if future.cancelled():  # Account logged out
                return

            try:
                account.max_upload_size = future.result() or 0
            except Exception:
                trace = traceback.format_exc().rstrip()
                log.warn(
                    "On %s server config retrieval: %s", self.user_id, trace,
                )
                self.server_config_task = asyncio.ensure_future(
                    self.get_server_config(),
                )
                self.server_config_task.add_done_callback(
                    on_server_config_response,
                )

        account = self.models["accounts"][self.user_id]

        # Get or create presence for account
        presence = self.backend.presences.setdefault(self.user_id, Presence())
        presence.account = account
        presence.presence = Presence.State(self._presence)

        self.profile_task = asyncio.ensure_future(self.update_own_profile())

        self.server_config_task = asyncio.ensure_future(
            self.get_server_config(),
        )
        self.server_config_task.add_done_callback(on_server_config_response)

        await self.auto_verify_all_other_accounts()

        while True:
            try:
                sync_filter_ids = await self.sync_filter_ids()

                self.sync_task = asyncio.ensure_future(self.sync_forever(
                    timeout           = 10_000,
                    loop_sleep_time   = 1000,
                    first_sync_filter = sync_filter_ids.first,
                    sync_filter       = sync_filter_ids.others,
                ))
                await self.sync_task
                break  # task cancelled
            except Exception as err:
                self.last_sync_error = err

                trace = traceback.format_exc().rstrip()

                if isinstance(err, MatrixError) and err.http_code >= 500:
                    log.warning(
                        "Server failure during sync for %s:\n%s",
                        self.user_id,
                        trace,
                    )
                else:
                    LoopException(str(err), err, trace)
            else:
                self.last_sync_error = None

            await asyncio.sleep(5)


    async def _stop(self) -> None:
        """Stop client tasks. Will prevent client to receive further events."""

        # Remove account model from presence update
        presence = self.backend.presences.get(self.user_id, None)

        if presence:
            presence.account = None

        tasks = (
            self.profile_task,
            self.sync_task,
            self.server_config_task,
            self.start_task,
        )

        for task in tasks:
            if task:
                task.cancel()
                with suppress(asyncio.CancelledError):
                    await task

        self.first_sync_done.clear()


    async def update_own_profile(self) -> None:
        """Fetch our profile from server and Update our model `Account`."""

        resp = await self.backend.get_profile(self.user_id, use_cache=False)

        account = self.models["accounts"][self.user_id]
        account.set_fields(
            profile_updated = datetime.now(),
            display_name    = resp.displayname or "",
            avatar_url      = resp.avatar_url or "",
        )


    async def get_server_config(self) -> int:
        """Return the maximum upload size on this server"""
        return (await self.content_repository_config()).upload_size


    async def sync_filter_ids(self) -> SyncFilterIds:
        """Return our sync/messages filter IDs, upload them if needed."""

        async with self._sync_filter_ids_lock:
            if self._sync_filter_ids:
                return self._sync_filter_ids

            others = deepcopy(self.lazy_load_filter)
            first  = deepcopy(others)

            utils.dict_update_recursive(first, self.low_limit_filter)

            if self.backend.ui_settings["hideUnknownEvents"]:
                first["room"]["timeline"]["not_types"].extend(
                    self.no_unknown_events_filter
                    ["room"]["timeline"]["not_types"],
                )

            others_id = (await self.upload_filter(**others)).filter_id
            first_id  = others_id

            if others != first:
                resp     = await self.upload_filter(**first)
                first_id = resp.filter_id

            self._sync_filter_ids = SyncFilterIds(others_id, first_id)
            return self._sync_filter_ids


    async def pause_while_offline(self) -> None:
        """Block until our account is online."""
        while (
            self.models["accounts"][self.user_id].presence ==
            Presence.State.offline
        ):
            await asyncio.sleep(0.2)


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


    async def send_text(
        self,
        room_id:               str,
        text:                  str,
        display_name_mentions: Optional[Dict[str, str]] = None,  # {name: id}
        reply_to_event_id:     Optional[str]            = None,
    ) -> None:
        """Send a markdown `m.text` or `m.notice` (with `/me`) message ."""

        from_md = partial(
            HTML.from_markdown, display_name_mentions=display_name_mentions,
        )

        escape = False
        if text.startswith("//") or text.startswith(r"\/"):
            escape = True
            text   = text[1:]

        content: Dict[str, Any]

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

        if reply_to_event_id:
            to: Event = \
                self.models[self.user_id, room_id, "events"][reply_to_event_id]

            source_body = getattr(to.source, "body", "")

            content["format"] = "org.matrix.custom.html"
            plain_source_body = "\n".join(
                f"> <{to.sender_id}> {line}" if i == 0 else f"> {line}"
                for i, line in enumerate(source_body.splitlines())
        )
            content["body"]   = f"{plain_source_body}\n\n{text}"

            to_html = REPLY_FALLBACK.format(
                room_id  = room_id,
                event_id = to.event_id,
                user_id  = to.sender_id,
                content  =
                    getattr(to.source, "formatted_body", "") or
                    source_body or
                    html.escape(to.source.source["type"] if to.source else ""),

                reply_content = to_html,
            )

            echo_body                 = HTML.filter(to_html)
            content["formatted_body"] = HTML.filter(to_html, outgoing=True)

            content["m.relates_to"] = {
                "m.in_reply_to": { "event_id": to.event_id },
            }

        # Can't use the standard Matrix transaction IDs; they're only visible
        # to the sender so our other accounts wouldn't be able to replace
        # local echoes by real messages.
        tx_id = uuid4()
        content[f"{__app_name__}.transaction_id"] = str(tx_id)

        mentions = HTML.mentions_in_html(echo_body)
        await self._local_echo(
            room_id,
            tx_id,
            event_type,
            content  = echo_body,
            mentions = mentions,
        )

        await self.pause_while_offline()
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


    async def send_clipboard_image(self, room_id: str, image: bytes) -> None:
        """Send a clipboard image passed from QML as a `m.image` message."""

        prefix = datetime.now().strftime("%Y%m%d-%H%M%S.")

        with NamedTemporaryFile(prefix=prefix, suffix=".png") as temp:

            async def get_path() -> Path:
                # optimize is too slow for large images
                compressed = await utils.compress_image(image, optimize=False)

                async with aiofiles.open(temp.name, "wb") as file:
                    await file.write(compressed)

                return Path(temp.name)

            await self.send_file(room_id, get_path)


    async def send_file(self, room_id: str, path: PathCallable) -> None:
        """Send a `m.file`, `m.image`, `m.audio` or `m.video` message."""

        item_uuid = uuid4()

        try:
            await self._send_file(item_uuid, room_id, path)
        except (nio.TransferCancelledError, asyncio.CancelledError):
            self.upload_monitors.pop(item_uuid, None)
            self.upload_tasks.pop(item_uuid, None)
            self.models[room_id, "uploads"].pop(str(item_uuid), None)


    async def _send_file(
        self, item_uuid: UUID, room_id: str, path: PathCallable,
    ) -> None:
        """Upload and monitor a file + thumbnail and send the built event."""

        # TODO: this function is way too complex, and most of it should be
        # refactored into nio.

        self.upload_tasks[item_uuid]    = current_task()  # type: ignore

        upload_item = Upload(item_uuid)
        self.models[room_id, "uploads"][str(item_uuid)] = upload_item

        transaction_id   = uuid4()
        path             = Path(await path() if callable(path) else path)
        encrypt          = room_id in self.encrypted_rooms

        thumb_crypt_dict: Dict[str, Any] = {}
        crypt_dict:       Dict[str, Any] = {}

        try:
            size = path.resolve().stat().st_size
        except (PermissionError, FileNotFoundError):
            # This error will be caught again by the try block later below
            size = 0

        upload_item.set_fields(
            status=UploadStatus.Uploading, filepath=path, total_size=size,
        )

        monitor = nio.TransferMonitor(size)
        self.upload_monitors[item_uuid] = monitor

        def on_transferred(transferred: int) -> None:
            upload_item.uploaded  = transferred

        def on_speed_changed(speed: float) -> None:
            upload_item.set_fields(
                speed     = speed,
                time_left = monitor.remaining_time or timedelta(0),
            )

        monitor.on_transferred   = on_transferred
        monitor.on_speed_changed = on_speed_changed

        await self.pause_while_offline()

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
            upload_item.set_fields(
                status     = UploadStatus.Error,
                error      = type(err),
                error_args = err.args,
            )

            # Wait for cancellation from UI, see parent send_file() method
            while True:
                await asyncio.sleep(0.1)

        upload_item.status = UploadStatus.Caching
        local_media        = await Media.from_existing_file(
            self.backend.media_cache, url, path,
        )

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

                upload_item.set_fields(
                    status     = UploadStatus.Uploading,
                    filepath   = Path(thumb_name),
                    total_size = len(thumb_data),
                )

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
            inline_content = content["body"],

            media_url        = url,
            media_http_url   = await self.mxc_to_http(url),
            media_title      = path.name,
            media_width      = content["info"].get("w", 0),
            media_height     = content["info"].get("h", 0),
            media_duration   = content["info"].get("duration", 0),
            media_size       = content["info"]["size"],
            media_mime       = content["info"]["mimetype"],
            media_crypt_dict = crypt_dict,
            media_local_path = await local_media.get_local(),

            thumbnail_url        = thumb_url,
            thumbnail_crypt_dict = thumb_crypt_dict,

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

        our_info = self.models["accounts"][self.user_id]

        content = event_fields.get("content", "").strip()

        if content and "inline_content" not in event_fields:
            event_fields["inline_content"] = HTML.filter(content, inline=True)

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

        # Room may be gone by the time this is called due to room_forget()
        room = self.all_rooms.get(room_id)

        if room and not room.members_synced:
            await super().joined_members(room_id)
            await self.register_nio_room(room, force_register_members=True)


    async def load_past_events(self, room_id: str) -> bool:
        """Ask the server for previous events of the room.

        If it's the first time that the room is being loaded, 10 events
        will be requested (to give the user something to read quickly), else
        100 events will be requested.

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
            limit          = 100 if room_id in self.loaded_once_rooms else 10,
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

        await self.update_account_unread_counts()

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
            except (MatrixNotFound, MatrixBadGateway) as err:
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


    async def room_put_state_builder(
        self, room_id: str, builder: nio.EventBuilder,
    ) -> str:
        """Send state event to room based from a `nio.EventBuilder` object."""

        dct = builder.as_dict()

        response = await self.room_put_state(
            room_id    = room_id,
            event_type = dct["type"],
            content    = dct["content"],
            state_key  = dct["state_key"],
        )
        return response.event_id


    async def room_set(
        self,
        room_id:        str,
        name:           Optional[str]  = None,
        topic:          Optional[str]  = None,
        encrypt:        Optional[bool] = None,
        require_invite: Optional[bool] = None,
        forbid_guests:  Optional[bool] = None,
    ) -> None:
        """Send setting state events for arguments that aren't `None`."""

        builders: List[nio.EventBuilder] = []

        if name is not None:
            builders.append(nio.ChangeNameBuilder(name=name))

        if topic is not None:
            builders.append(nio.ChangeTopicBuilder(topic=topic))

        if encrypt is False:
            raise ValueError("Cannot disable encryption in a E2E room")

        if encrypt is True:
            builders.append(nio.EnableEncryptionBuilder())

        if require_invite is not None:
            builders.append(nio.ChangeJoinRulesBuilder(
                rule="invite" if require_invite else "public",
            ))

        if forbid_guests is not None:
            builders.append(nio.ChangeGuestAccessBuilder(
                access = "forbidden" if forbid_guests else "can_join",
            ))

        await asyncio.gather(*[
            self.room_put_state_builder(room_id, b) for b in builders
        ])


    async def room_set_member_power(
        self, room_id: str, user_id: str, level: int,
    ) -> None:
        """Set a room member's power level."""

        while room_id not in self.power_level_events:
            await asyncio.sleep(0.2)

        content = deepcopy(self.power_level_events[room_id].source["content"])
        content.setdefault("users", {})[user_id] = level

        await self.room_put_state(room_id, "m.room.power_levels", content)


    async def room_typing(
        self, room_id: str, typing_state: bool = True, timeout: int = 5000,
    ):
        """Set typing notice to the server."""

        # Do not send typing notice if the user is invisible
        presence = self.models["accounts"][self.user_id].presence
        if presence not in [Presence.State.invisible, Presence.State.offline]:
            await super().room_typing(room_id, typing_state, timeout)


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
            content = f"{content}, reason: {html.escape(reason)}"

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

        await self.pause_while_offline()
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

        if thumb.mode in png_modes:
            thumb_data = await utils.compress_image(thumb)
            mime       = "image/png"
        else:
            thumb      = thumb.convert("RGB")
            thumb_data = await utils.compress_image(thumb, "JPEG")
            mime       = "image/jpeg"

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

        max_size = self.models["accounts"][self.user_id].max_upload_size

        if max_size and filesize > max_size:
            raise MatrixTooLarge()

        mime = mime or await utils.guess_mime(data_provider(0, 0))

        response, decryption_dict = await super().upload(
            data_provider = data_provider,
            content_type  = "application/octet-stream" if encrypt else mime,
            filename      = filename,
            encrypt       = encrypt,
            monitor       = monitor,
            filesize      = filesize,
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


    async def get_offline_presence(self, user_id: str) -> None:
        """Get a offline room member's presence and set it on model item.

        This is called by QML when a member list delegate or profile that
        is offline is displayed.
        Since we don't get last seen times for offline in users in syncs,
        we have to fetch those manually.
        """

        if self.backend.presences.get(user_id):
            return

        if not self.models["accounts"][self.user_id].presence_support:
            return

        try:
            async with self.backend.concurrent_get_presence_limit:
                resp = await self.get_presence(user_id)
        except MatrixForbidden:
            return

        await self.nio_callbacks.onPresenceEvent(nio.PresenceEvent(
            user_id          = resp.user_id,
            presence         = resp.presence,
            last_active_ago  = resp.last_active_ago,
            currently_active = resp.currently_active,
            status_msg       = resp.status_msg,
        ))


    async def set_presence(
        self,
        presence:   str,
        status_msg: Optional[str] = None,
        save:       bool          = True,
    ) -> None:
        """Set presence state for this account."""

        account    = self.models["accounts"][self.user_id]
        status_msg = status_msg if status_msg is not None else (
            self.models["accounts"][self.user_id].status_msg
        )
        set_status_msg = True

        if presence == "offline":
            # Do not do anything if account is offline and setting to offline
            if account.presence == Presence.State.offline:
                return

            await self._stop()

            # Update manually since we may not receive the presence event back
            # in time
            account.set_fields(
                presence         = Presence.State.offline,
                currently_active = False,
            )
        elif (
            account.presence == Presence.State.offline and
            presence         != "offline"
        ):
            # In this case we will not run super().set_presence()
            set_status_msg     = False
            account.connecting = True
            self.start_task    = asyncio.ensure_future(self._start())

            self._presence = "offline" if presence == "invisible" else presence

        if (
            Presence.State(presence) != account.presence and
            presence                 != "offline"
        ):
            account.presence = Presence.State("echo_" + presence)

        if not account.presence_support:
            account.presence = Presence.State(presence)

        if save:
            account.save_presence = True
            await self.backend.saved_accounts.update(
                self.user_id, presence=presence, status_msg=status_msg,
            )
        else:
            account.save_presence = False

        if set_status_msg:
            account.status_msg = status_msg

            await super().set_presence(
                "offline"  if presence == "invisible" else presence,
                status_msg,
            )


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

            with model.write_lock:
                for ev in model.values():
                    room = self.all_rooms[room_id]

                    if isinstance(ev.source, nio.MegolmEvent):
                        try:
                            decrypted = self.decrypt_event(ev.source)

                            if not decrypted:
                                raise nio.EncryptionError()

                        except nio.EncryptionError:
                            continue

                        for callback in self.event_callbacks:
                            filter_ = callback.filter
                            if not filter_ or isinstance(decrypted, filter_):
                                coro = asyncio.coroutine(callback.func)
                                await coro(room, decrypted)


    async def clear_events(self, room_id: str) -> None:
        """Remove every `Event` of a room we registered in our model.

        The events will be gone from the UI, until the client is restarted.
        """

        self.cleared_events_rooms.add(room_id)

        model = self.models[self.user_id, room_id, "events"]
        if model:
            model.clear()

        self.models[self.user_id, "rooms"][room_id].last_event_date = \
            ZERO_DATE


    async def devices_info(self) -> List[Dict[str, Any]]:
        """Get sorted list of devices and their info for our user."""

        def get_type(device_id: str) -> str:
            # Return "current", "no_keys", "verified", "blacklisted",
            # "ignored" or "unset"

            if device_id == self.device_id:
                return "current"

            if device_id not in self.device_store[self.user_id]:
                return "no_keys"

            trust = self.device_store[self.user_id][device_id].trust_state
            return trust.name

        def get_ed25519(device_id: str) -> str:
            key = ""

            if device_id == self.device_id:
                key = self.olm.account.identity_keys["ed25519"]
            elif device_id in self.device_store[self.user_id]:
                key = self.device_store[self.user_id][device_id].ed25519

            return " ".join(textwrap.wrap(key, 4))

        devices = [
            {
                "id":                device.id,
                "display_name":      device.display_name or "",
                "last_seen_ip":      (device.last_seen_ip or "").strip(" -"),
                "last_seen_date":    device.last_seen_date or ZERO_DATE,
                "last_seen_country": "",
                "type":              get_type(device.id),
                "ed25519_key":       get_ed25519(device.id),
            }
            for device in (await self.devices()).devices
        ]

        # Reversed due to sorted(reverse=True) call below
        types_order = {
            "current": 5,
            "unset": 4,
            "no_keys": 3,
            "verified": 2,
            "ignored": 1,
            "blacklisted": 0,
        }

        # Sort by type, then by descending date
        return sorted(
            devices,
            key     = lambda d: (types_order[d["type"]], d["last_seen_date"]),
            reverse = True,
        )


    async def member_devices(self, user_id: str) -> List[Dict[str, Any]]:
        """Get list of E2E-aware devices for a user we share a room with."""

        devices = [
            # types: "verified", "blacklisted", "ignored" or "unset"
            {
                "id":           device.id,
                "display_name": device.display_name or "",
                "type":         device.trust_state.name,
                "ed25519_key":  " ".join(textwrap.wrap(device.ed25519, 4)),
            }
            for device in self.device_store.active_user_devices(user_id)
        ]

        types_order = {
            "unset": 0, "verified": 1, "ignored": 2, "blacklisted": 3,
        }

        # Sort by type, then by display name, then by ID
        return sorted(
            devices,
            key = lambda d:
                (types_order[d["type"]], d["display_name"], d["id"]),
        )


    async def rename_device(self, device_id: str, name: str) -> bool:
        """Rename one of our device, return `False` if it doesn't exist."""

        try:
            await self.update_device(device_id, {"display_name": name})
            return True
        except MatrixNotFound:
            return False


    async def auto_verify_all_other_accounts(self) -> None:
        """Automatically verify/blacklist our other accounts's devices."""

        for client in self.backend.clients.values():
            await self.auto_verify_account(client)


    async def auto_verify_account(self, client: "MatrixClient") -> None:
        """Automatically verify/blacklist one of our accounts's devices."""

        if client.user_id == self.user_id:
            return

        for device in self.device_store.active_user_devices(client.user_id):
            if device.device_id != client.device_id:
                continue

            if device.verified or device.blacklisted:
                continue

            if device.ed25519 == client.olm.account.identity_keys["ed25519"]:
                self.verify_device(device)
            else:
                self.blacklist_device(device)


    async def delete_devices_with_password(
        self, device_ids: List[str], password: str,
    ) -> None:
        """Delete devices, authentifying using the account's password."""

        auth = {
            "type":     "m.login.password",
            "user":     self.user_id,
            "password": password,
        }

        resp = await super().delete_devices(device_ids, auth)

        if isinstance(resp, nio.DeleteDevicesAuthResponse):
            raise MatrixUnauthorized()


    # Functions to register/modify data into models

    async def update_account_unread_counts(self) -> None:
        """Recalculate total unread notifications/highlights for our account"""

        unreads          = 0
        highlights       = 0
        local_unreads    = False
        local_highlights = False

        for room in self.models[self.user_id, "rooms"].values():
            unreads    += room.unreads
            highlights += room.highlights

            if room.local_unreads:
                local_unreads = True

            if room.local_highlights:
                local_highlights = True

        account = self.models["accounts"][self.user_id]
        account.set_fields(
            total_unread     = unreads,
            total_highlights = highlights,
            local_unreads    = local_unreads,
            local_highlights = local_highlights,
        )


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
        self,
        room:                   nio.MatrixRoom,
        left:                   bool = False,
        force_register_members: bool = False,
    ) -> None:
        """Register/update a `nio.MatrixRoom` as a `models.items.Room`."""

        # Add room
        inviter        = getattr(room, "inviter", "") or ""
        levels         = room.power_levels
        can_send_state = partial(levels.can_user_send_state, self.user_id)
        can_send_msg   = partial(levels.can_user_send_message, self.user_id)

        try:
            registered = self.models[self.user_id, "rooms"][room.room_id]
        except KeyError:
            registered                   = None
            last_event_date              = datetime.fromtimestamp(0)
            typing_members               = []
            local_unreads                = False
            local_highlights             = False
            update_account_unread_counts = True
            unverified_devices           = (
                False
                if isinstance(room, nio.MatrixInvitedRoom) else
                self.room_contains_unverified(room.room_id)
            )
        else:
            last_event_date              = registered.last_event_date
            typing_members               = registered.typing_members
            local_unreads                = registered.local_unreads
            local_highlights             = registered.local_highlights
            update_account_unread_counts = (
                registered.unreads != room.unread_notifications or
                registered.highlights != room.unread_highlights
            )
            unverified_devices = registered.unverified_devices

        room_item = Room(
            id             = room.room_id,
            for_account    = self.user_id,
            given_name     = room.name or "",
            display_name   = room.display_name or "",
            avatar_url     = room.gen_avatar_url or "",
            plain_topic    = room.topic or "",
            topic          = HTML.filter(
                utils.plain2html(room.topic or ""),
                inline = True,
            ),
            inviter_id     = inviter,
            inviter_name   = room.user_name(inviter) if inviter else "",
            inviter_avatar =
                (room.avatar_url(inviter) or "") if inviter else "",
            left           = left,

            typing_members = typing_members,

            encrypted          = room.encrypted,
            unverified_devices = unverified_devices,
            invite_required    = room.join_rule == "invite",
            guests_allowed     = room.guest_access == "can_join",

            default_power_level  = levels.defaults.users_default,
            own_power_level      = levels.get_user_level(self.user_id),
            can_invite           = levels.can_user_invite(self.user_id),
            can_kick             = levels.can_user_kick(self.user_id),
            can_redact_all       = levels.can_user_redact(self.user_id),
            can_send_messages    = can_send_msg(),
            can_set_name         = can_send_state("m.room.name"),
            can_set_topic        = can_send_state("m.room.topic"),
            can_set_avatar       = can_send_state("m.room.avatar"),
            can_set_encryption   = can_send_state("m.room.encryption"),
            can_set_join_rules   = can_send_state("m.room.join_rules"),
            can_set_guest_access = can_send_state("m.room.guest_access"),
            can_set_power_levels = can_send_state("m.room.power_levels"),

            last_event_date = last_event_date,

            unreads          = room.unread_notifications,
            highlights       = room.unread_highlights,
            local_unreads    = local_unreads,
            local_highlights = local_highlights,
        )

        self.models[self.user_id, "rooms"][room.room_id] = room_item

        if not registered or force_register_members:
            for user_id in room.users:
                await self.add_member(room, user_id)

        if update_account_unread_counts:
            await self.update_account_unread_counts()


    async def add_member(self, room: nio.MatrixRoom, user_id: str) -> None:
        """Register/update a room member into our models."""
        member      = room.users[user_id]
        presence    = self.backend.presences.get(user_id, None)
        member_item = Member(
            id           = user_id,
            display_name = room.user_name(user_id)  # disambiguated
                           if member.display_name else "",
            avatar_url   = member.avatar_url or "",
            typing       = user_id in room.typing_users,
            power_level  = member.power_level,
            invited      = member.invited,
        )

        # Associate presence with member, if it exists
        if presence:
            presence.members[room.room_id] = member_item

            # And then update presence fields
            presence.update_members()

        self.models[self.user_id, room.room_id, "members"][user_id] = \
            member_item


    async def remove_member(self, room: nio.MatrixRoom, user_id: str) -> None:
        """Remove a room member from our models."""

        self.models[self.user_id, room.room_id, "members"].pop(user_id, None)

        room_item = self.models[self.user_id, "rooms"].get(room.room_id)

        if room_item:
            room_item.unverified_devices = \
                self.room_contains_unverified(room.room_id)


    async def get_event_profiles(self, room_id: str, event_id: str) -> None:
        """Fetch from network an event's sender, target and remover's profile.

        This should be called from QML, see `MatrixClient.get_member_profile`'s
        docstring.
        """

        ev: Event = self.models[self.user_id, room_id, "events"][event_id]

        if not ev.fetch_profile:
            return

        get_profile = partial(
            self.get_member_profile, room_id, can_fetch_from_network=True,
        )

        if not ev.sender_name and not ev.sender_avatar:
            sender_name, sender_avatar, _ = await get_profile(ev.sender_id)
            ev.set_fields(sender_name=sender_name, sender_avatar=sender_avatar)

        if ev.target_id and not ev.target_name and not ev.target_avatar:
            target_name, target_avatar, _ = await get_profile(ev.target_id)
            ev.set_fields(target_name=target_name, target_avatar=target_avatar)

        if ev.redacter_id and not ev.redacter_name:
            redacter_name, _, _ = await get_profile(ev.target_id)
            ev.redacter_name    = redacter_name

        ev.fetch_profile = False


    async def get_member_profile(
        self, room_id: str, user_id: str, can_fetch_from_network: bool = False,
    ) -> Tuple[str, str, bool]:
        """Return a room member's (display_name, avatar, should_lazy_fetch)

        The returned tuple's last element tells whether
        `MatrixClient.get_event_profiles()` should be called by QML
        with `can_fetch_from_network = True` when appropriate,
        e.g. when this message comes in the user's view.

        If the member isn't found in the room (e.g. they left) and
        `can_fetch_from_network` is `True`, their
        profile is retrieved using `MatrixClient.backend.get_profile()`.
        """

        try:
            member = self.models[self.user_id, room_id, "members"][user_id]
            return (member.display_name, member.avatar_url, False)

        except KeyError:  # e.g. member is not in the room anymore
            if not can_fetch_from_network:
                return ("", "", True)

            try:
                info = await self.backend.get_profile(user_id)
                return (info.displayname or "", info.avatar_url or "", False)
            except MatrixError:
                return ("", "", False)


    async def register_nio_event(
        self,
        room:                   nio.MatrixRoom,
        ev:                     nio.Event,
        event_id:               str            = "",
        override_fetch_profile: Optional[bool] = None,
        **fields,
    ) -> Event:
        """Register/update a `nio.Event` as a `models.items.Event` object."""

        await self.register_nio_room(room)

        sender_name, sender_avatar, must_fetch_sender = \
            await self.get_member_profile(room.room_id, ev.sender)

        target_id = getattr(ev, "state_key", "") or ""

        target_name, target_avatar, must_fetch_target = \
            await self.get_member_profile(room.room_id, target_id) \
            if target_id else ("", "", False)

        content = fields.get("content", "").strip()

        if content and "inline_content" not in fields:
            fields["inline_content"] = HTML.filter(content, inline=True)

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

            fetch_profile =
                (must_fetch_sender or must_fetch_target)
                if override_fetch_profile is None else
                override_fetch_profile,
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
            return item

        mentions_us = HTML.user_id_link_in_html(item.content, self.user_id)
        AlertRequested(high_importance=mentions_us)

        room_item = self.models[self.user_id, "rooms"][room.room_id]
        room_item.local_unreads = True

        if mentions_us:
            room_item.local_highlights = True

        await self.update_account_unread_counts()
        return item
