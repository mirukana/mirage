import asyncio
import functools
import html
import io
import logging as log
import platform
import re
import traceback
from contextlib import suppress
from datetime import datetime
from functools import partial
from pathlib import Path
from typing import (
    Any, BinaryIO, DefaultDict, Dict, Optional, Set, Tuple, Type, Union,
)
from urllib.parse import urlparse
from uuid import uuid4

import cairosvg
from PIL import Image as PILImage
from pymediainfo import MediaInfo

import nio

from . import __about__, utils
from .errors import (
    InvalidUserInContext, MatrixError, UneededThumbnail, UnthumbnailableError,
    UserNotFound,
)
from .html_filter import HTML_FILTER
from .models.items import (
    Account, Event, Member, Room, TypeSpecifier, Upload, UploadStatus,
)
from .models.model_store import ModelStore
from .pyotherside_events import AlertRequested

CryptDict = Dict[str, Any]


class MatrixClient(nio.AsyncClient):
    def __init__(self,
                 backend,
                 user:       str,
                 homeserver: str           = "https://matrix.org",
                 device_id:  Optional[str] = None) -> None:

        store = Path(backend.app.appdirs.user_data_dir) / "encryption"
        store.mkdir(parents=True, exist_ok=True)

        # TODO: ensure homeserver starts by a scheme://
        # TODO: pass a ClientConfig with a pickle key
        super().__init__(
            homeserver = homeserver,
            user       = user,
            device_id  = device_id,
            store_path = store,
            config     = nio.AsyncClientConfig(
                max_timeout_retry_wait_time = 10,
            ),
        )

        from .backend import Backend
        self.backend: Backend    = backend
        self.models:  ModelStore = self.backend.models

        self.sync_task:       Optional[asyncio.Future] = None
        self.first_sync_done: asyncio.Event            = asyncio.Event()
        self.first_sync_date: Optional[datetime]       = None

        self.send_locks: DefaultDict[str, asyncio.Lock] = \
                DefaultDict(asyncio.Lock)  # {room_id: lock}

        self.past_tokens:          Dict[str, str] = {}     # {room_id: token}
        self.fully_loaded_rooms:   Set[str]       = set()  # {room_id}
        self.loaded_once_rooms:    Set[str]       = set()  # {room_id}
        self.cleared_events_rooms: Set[str]       = set()  # {room_id}

        self.local_echoes_uuid: Set[str]       = set()
        self.resolved_echoes:   Dict[str, str] = {}  # {event_id: echo_uuid}

        self.skipped_events: DefaultDict[str, int] = DefaultDict(lambda: 0)

        from .media_cache import MediaCache
        cache_dir        = Path(self.backend.app.appdirs.user_cache_dir)
        self.media_cache = MediaCache(self, cache_dir)

        from .nio_callbacks import NioCallbacks
        self.nio_callbacks = NioCallbacks(self)


    def __repr__(self) -> str:
        return "%s(user_id=%r, homeserver=%r, device_id=%r)" % (
            type(self).__name__, self.user_id, self.homeserver, self.device_id,
        )


    @property
    def default_device_name(self) -> str:
        os_ = f" on {platform.system()}".rstrip()
        os_ = f"{os_} {platform.release()}".rstrip() if os_ != " on" else ""
        return f"{__about__.__pretty_name__}{os_}"


    async def login(self, password: str, device_name: str = "") -> None:
        response = await super().login(
            password, device_name or self.default_device_name,
        )

        if isinstance(response, nio.LoginError):
            raise MatrixError.from_nio(response)

        asyncio.ensure_future(self.start())


    async def resume(self, user_id: str, token: str, device_id: str) -> None:
        response = nio.LoginResponse(user_id, device_id, token)
        await self.receive_response(response)
        asyncio.ensure_future(self.start())


    async def logout(self) -> None:
        if self.sync_task:
            self.sync_task.cancel()
            with suppress(asyncio.CancelledError):
                await self.sync_task

        await super().logout()
        await self.close()


    async def start(self) -> None:
        def on_profile_response(future) -> None:
            if future.exception():
                return

            resp                    = future.result()
            account                 = self.models[Account][self.user_id]
            account.profile_updated = datetime.now()
            account.display_name    = resp.displayname or ""
            account.avatar_url      = resp.avatar_url or ""

        ft = asyncio.ensure_future(self.backend.get_profile(self.user_id))
        ft.add_done_callback(on_profile_response)

        while True:
            try:
                await self.sync_forever(timeout=10_000)
            except Exception:
                trace = traceback.format_exc().rstrip()
                log.error("Exception during sync, will restart:\n%s", trace)
                await asyncio.sleep(2)


    @property
    def all_rooms(self) -> Dict[str, nio.MatrixRoom]:
        return {**self.invited_rooms, **self.rooms}


    async def send_text(self, room_id: str, text: str) -> None:
        escape = False
        if text.startswith("//") or text.startswith(r"\/"):
            escape = True
            text   = text[1:]

        if text.startswith("/me ") and not escape:
            event_type = nio.RoomMessageEmote
            text       = text[len("/me "): ]
            content    = {"body": text, "msgtype": "m.emote"}
            to_html    = HTML_FILTER.from_markdown_inline(text, outgoing=True)
            echo_body  = HTML_FILTER.from_markdown_inline(text)
        else:
            event_type = nio.RoomMessageText
            content    = {"body": text, "msgtype": "m.text"}
            to_html    = HTML_FILTER.from_markdown(text, outgoing=True)
            echo_body  = HTML_FILTER.from_markdown(text)

        if to_html not in (html.escape(text), f"<p>{html.escape(text)}</p>"):
            content["format"]         = "org.matrix.custom.html"
            content["formatted_body"] = to_html

        uuid = str(uuid4())

        await self._local_echo(room_id, uuid, event_type, content=echo_body)
        await self._send_message(room_id, uuid, content)


    async def send_file(self, room_id: str, path: Union[Path, str]) -> None:
        path    = Path(path)
        size    = path.resolve().stat().st_size
        encrypt = room_id in self.encrypted_rooms

        upload_item = Upload(str(path), total_size=size)
        self.models[Upload, room_id][upload_item.uuid] = upload_item

        url, mime, crypt_dict = await self.upload_file(
            path, upload_item, encrypt=encrypt,
        )

        await self.media_cache.create_media(url, path.read_bytes())

        kind = (mime or "").split("/")[0]

        thumb_url:  str            = ""
        thumb_info: Dict[str, Any] = {}

        content: dict = {
            "body": path.name,
            "info": {
                "mimetype": mime,
                "size":     size,
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
                utils.svg_dimensions(str(path)) if is_svg else
                PILImage.open(path).size
            )

            try:
                thumb_data, thumb_url, thumb_info, thumb_crypt_dict = \
                    await self.upload_thumbnail(
                        path, upload_item, is_svg=is_svg, encrypt=encrypt,
                    )
            except (UneededThumbnail, UnthumbnailableError):
                pass
            else:
                await self.media_cache.create_thumbnail(
                    thumb_url,
                    thumb_data,
                    content["info"]["w"],
                    content["info"]["h"],
                )

                if encrypt:
                    content["info"]["thumbnail_file"]  = {
                        "url": thumb_url,
                        **thumb_crypt_dict,
                    }
                else:
                    content["info"]["thumbnail_url"]  = thumb_url

                content["info"]["thumbnail_info"] = thumb_info

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

        del self.models[Upload, room_id][upload_item.uuid]

        uuid = str(uuid4())

        await self._local_echo(
            room_id, uuid, event_type,
            inline_content   = path.name,
            media_url        = url,
            media_title      = path.name,
            media_width      = content["info"].get("w", 0),
            media_height     = content["info"].get("h", 0),
            media_duration   = content["info"].get("duration", 0),
            media_size       = content["info"]["size"],
            media_mime       = content["info"]["mimetype"],
            thumbnail_url    = thumb_url,
            thumbnail_width  = thumb_info.get("w", 0),
            thumbnail_height = thumb_info.get("h", 0),
        )

        await self._send_message(room_id, uuid, content)


    async def _local_echo(
        self, room_id: str, uuid: str,
        event_type: Type[nio.Event], **event_fields,
    ) -> None:

        our_info = self.models[Member, room_id][self.user_id]

        event = Event(
            source           = None,
            client_id        = f"echo-{uuid}",
            event_id         = "",
            date             = datetime.now(),
            sender_id        = self.user_id,
            sender_name      = our_info.display_name,
            sender_avatar    = our_info.avatar_url,
            is_local_echo    = True,
            local_event_type = event_type,
            **event_fields,
        )

        self.local_echoes_uuid.add(uuid)

        for user_id in self.models[Account]:
            if user_id in self.models[Member, room_id]:
                self.models[Event, user_id, room_id][f"echo-{uuid}"] = event
                self.models[Event, user_id, room_id].sync_now()

        await self.set_room_last_event(room_id, event)


    async def _send_message(self, room_id: str, uuid: str, content: dict,
                           ) -> None:

        async with self.send_locks[room_id]:
            response = await self.room_send(
                room_id                   = room_id,
                message_type              = "m.room.message",
                content                   = content,
                tx_id                     = uuid,
                ignore_unverified_devices = True,
            )

            if isinstance(response, nio.RoomSendError):
                raise MatrixError.from_nio(response)


    async def load_past_events(self, room_id: str) -> bool:
        if room_id in self.fully_loaded_rooms or \
           room_id in self.invited_rooms or \
           room_id in self.cleared_events_rooms:
            return False

        await self.first_sync_done.wait()

        response = await self.room_messages(
            room_id = room_id,
            start   = self.past_tokens[room_id],
            limit   = 100 if room_id in self.loaded_once_rooms else 25,
        )

        if isinstance(response, nio.RoomMessagesError):
            log.error("Loading past messages for room %s failed: %s",
                      room_id, response)
            return True

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


    async def load_rooms_without_visible_events(self) -> None:
        for room_id in self.models[Room, self.user_id]:
            asyncio.ensure_future(
                self._load_room_without_visible_events(room_id),
            )


    async def _load_room_without_visible_events(self, room_id: str) -> None:
        events = self.models[Event, self.user_id, room_id]
        more   = True

        while self.skipped_events[room_id] and not events and more:
            more = await self.load_past_events(room_id)


    async def new_direct_chat(self, invite: str, encrypt: bool = False) -> str:
        if invite == self.user_id:
            raise InvalidUserInContext(invite)

        try:
            await self.get_profile(invite)
        except MatrixError:
            raise UserNotFound(invite)

        response = await super().room_create(
            invite        = [invite],
            is_direct     = True,
            visibility    = nio.RoomVisibility.private,
            initial_state =
                [nio.EnableEncryptionBuilder().as_dict()] if encrypt else [],
        )

        if isinstance(response, nio.RoomCreateError):
            raise MatrixError.from_nio(response)

        return response.room_id


    async def new_group_chat(
        self,
        name:     Optional[str] = None,
        topic:    Optional[str] = None,
        public:   bool          = False,
        encrypt:  bool          = False,
        federate: bool          = True,
    ) -> str:

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

        if isinstance(response, nio.RoomCreateError):
            raise MatrixError.from_nio(response)

        return response.room_id

    async def room_join(self, alias_or_id_or_url: str) -> str:
        string = alias_or_id_or_url.strip()

        if re.match(r"^https?://", string):
            for part in urlparse(string).fragment.split("/"):
                if re.match(r"^[#!].+:.+", part):
                    string = part
                    break
            else:
                raise ValueError(f"No alias or room id found in url {string}")

        if not re.match(r"^[#!].+:.+", string):
            raise ValueError("Not an alias or room id")

        response = await super().join(string)

        if isinstance(response, nio.JoinError):
            raise MatrixError.from_nio(response)

        return response.room_id



    async def room_forget(self, room_id: str) -> None:
        await super().room_leave(room_id)
        await super().room_forget(room_id)
        self.models[Room, self.user_id].pop(room_id, None)
        self.models.pop((Event, self.user_id, room_id), None)
        self.models.pop((Member, room_id), None)


    async def encrypt_attachment(self, data: bytes) -> Tuple[bytes, CryptDict]:
        func = functools.partial(
            nio.crypto.attachments.encrypt_attachment,
            data,
        )

        # Run in a separate thread
        return await asyncio.get_event_loop().run_in_executor(None, func)


    async def upload_thumbnail(
        self,
        path:    Union[Path, str],
        item:    Optional[Upload] = None,
        is_svg:  bool             = False,
        encrypt: bool             = False,
    ) -> Tuple[bytes, str, Dict[str, Any], CryptDict]:

        png_modes = ("1", "L", "P", "RGBA")

        try:
            if is_svg:
                svg_width, svg_height = utils.svg_dimensions(str(path))

                thumb = PILImage.open(io.BytesIO(
                    cairosvg.svg2png(
                        url           = str(path),
                        parent_width  = svg_width,
                        parent_height = svg_height,
                    ),
                ))
            else:
                thumb = PILImage.open(path)

            small       = thumb.width <= 800 and thumb.height <= 600
            is_jpg_png  = thumb.format in ("JPEG", "PNG")
            jpgable_png = thumb.format == "PNG" and thumb.mode not in png_modes

            if small and is_jpg_png and not jpgable_png and not is_svg:
                raise UneededThumbnail()

            if item:
                item.status = UploadStatus.CreatingThumbnail

            if not small:
                thumb.thumbnail((800, 600), PILImage.LANCZOS)

            with io.BytesIO() as out:
                if thumb.mode in png_modes:
                    thumb.save(out, "PNG", optimize=True)
                    mime = "image/png"
                else:
                    thumb.convert("RGB").save(out, "JPEG", optimize=True)
                    mime = "image/jpeg"

                data = out.getvalue()

                if encrypt:
                    if item:
                        item.status = UploadStatus.EncryptingThumbnail

                    data, crypt_dict = await self.encrypt_attachment(data)
                    upload_mime      = "application/octet-stream"
                else:
                    crypt_dict, upload_mime = {}, mime

                if item:
                    item.status = UploadStatus.UploadingThumbnail

                return (
                    data,
                    await self.upload(data, upload_mime, Path(path).name),
                    {
                        "w":        thumb.width,
                        "h":        thumb.height,
                        "mimetype": mime,
                        "size":     len(data),
                    },
                    crypt_dict,
                )

        except OSError as err:
            log.warning("Error when creating thumbnail: %s", err)
            raise UnthumbnailableError(err)


    async def upload_file(
        self,
        path:    Union[Path, str],
        item:    Optional[Upload] = None,
        encrypt: bool             = False,
    ) -> Tuple[str, str, CryptDict]:

        with open(path, "rb") as file:
            mime = utils.guess_mime(file)
            file.seek(0, 0)

            data: Union[BinaryIO, bytes]

            if encrypt:
                if item:
                    item.status = UploadStatus.Encrypting

                data, crypt_dict = await self.encrypt_attachment(file.read())
                upload_mime      = "application/octet-stream"
            else:
                data, crypt_dict, upload_mime = file, {}, mime

            if item:
                item.status = UploadStatus.Uploading

            return (
                await self.upload(data, upload_mime, Path(path).name),
                mime,
                crypt_dict,
            )


    async def upload(self, data, mime: str, filename: Optional[str] = None,
                    ) -> str:
        response = await super().upload(data, mime, filename)

        if isinstance(response, nio.UploadError):
            raise MatrixError.from_nio(response)

        return response.content_uri


    async def set_avatar_from_file(self, path: Union[Path, str]) -> None:
        # TODO: check if mime is image
        await self.set_avatar((await self.upload_file(path))[0])


    async def import_keys(self, infile: str, passphrase: str) -> None:
        # Reimplemented until better solutions are worked on in nio
        await self.clear_import_error()

        loop = asyncio.get_event_loop()

        account     = self.models[Account][self.user_id]
        import_keys = partial(self.olm.import_keys_static, infile, passphrase)

        account.importing_key        = 0
        account.total_keys_to_import = -1  # preparing

        try:
            sessions = await loop.run_in_executor(None, import_keys)
        except nio.EncryptionError as err:  # XXX raise
            account.import_error = (infile, passphrase, str(err))
            return

        account.total_keys_to_import = len(sessions)

        for session in sessions:
            if self.olm.inbound_group_store.add(session):
                await loop.run_in_executor(
                    None, self.store.save_inbound_group_session, session,
                )
                account.importing_key += 1

        account.importing_key        = 0
        account.total_keys_to_import = 0

        await self.retry_decrypting_events()


    async def export_keys(self, outfile: str, passphrase: str) -> None:
        path = Path(outfile)
        path.parent.mkdir(parents=True, exist_ok=True)

        # The QML dialog asks the user if he wants to overwrite before this
        if path.exists():
            path.unlink()

        await super().export_keys(outfile, passphrase)


    async def clear_import_error(self) -> None:
        self.models[Account][self.user_id].import_error = ("", "", "")


    async def retry_decrypting_events(self) -> None:
        for sync_id, model in self.models.items():
            if not (isinstance(sync_id, tuple) and
                    sync_id[0:2] == (Event, self.user_id)):
                continue

            _, _, room_id = sync_id

            for ev in model.values():
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
        self.cleared_events_rooms.add(room_id)
        model = self.models[Event, self.user_id, room_id]
        if model:
            model.clear()
            model.sync_now()


    # Functions to register data into models

    async def event_is_past(self, ev: Union[nio.Event, Event]) -> bool:
        if not self.first_sync_date:
            return True

        if isinstance(ev, Event):
            return ev.date < self.first_sync_date

        date = datetime.fromtimestamp(ev.server_timestamp / 1000)
        return date < self.first_sync_date


    async def set_room_last_event(self, room_id: str, item: Event) -> None:
        model = self.models[Room, self.user_id]
        room  = model[room_id]

        if room.last_event is None:
            room.last_event = item.serialized

            if item.is_local_echo:
                model.sync_now()

            return

        is_profile_ev = item.type_specifier == TypeSpecifier.profile_change

        # If there were no better events available to show previously
        prev_is_profile_ev = \
            room.last_event["type_specifier"] == TypeSpecifier.profile_change

        # If this is a profile event, only replace the currently shown one if
        # it was also a profile event (we had nothing better to show).
        if is_profile_ev and not prev_is_profile_ev:
            return

        # If this event is older than the currently shown one, only replace
        # it if the previous was a profile event.
        if item.date < room.last_event["date"] and not prev_is_profile_ev:
            return

        room.last_event = item.serialized

        if item.is_local_echo:
            model.sync_now()


    async def register_nio_room(self, room: nio.MatrixRoom, left: bool = False,
                               ) -> None:
        # Add room
        try:
            last_ev = self.models[Room, self.user_id][room.room_id].last_event
        except KeyError:
            last_ev = None

        inviter = getattr(room, "inviter", "") or ""

        self.models[Room, self.user_id][room.room_id] = Room(
            room_id        = room.room_id,
            display_name   = room.display_name,
            avatar_url     = room.gen_avatar_url or "",
            topic          = HTML_FILTER.filter_inline(room.topic or ""),
            inviter_id     = inviter,
            inviter_name   = room.user_name(inviter) if inviter else "",
            inviter_avatar =
                (room.avatar_url(inviter) or "") if inviter else "",
            left           = left,
            last_event     = last_ev,
        )

        # Add the room members to the added room
        new_dict = {
            user_id: Member(
                user_id       = user_id,
                display_name  = room.user_name(user_id)  # disambiguated
                                if member.display_name else "",
                avatar_url    = member.avatar_url or "",
                typing        = user_id in room.typing_users,
                power_level   = member.power_level,
            ) for user_id, member in room.users.items()
        }
        self.models[Member, room.room_id].update(new_dict)


    async def get_member_name_avatar(self, room_id: str, user_id: str,
                                    ) -> Tuple[str, str]:
        try:
            item = self.models[Member, room_id][user_id]
        except KeyError:  # e.g. user is not anymore in the room
            try:
                info = await self.backend.get_profile(user_id)
                return (info.displayname or "", info.avatar_url or "")
            except MatrixError:
                return ("", "")
        else:
            return (item.display_name, item.avatar_url)


    async def register_nio_event(
        self, room: nio.MatrixRoom, ev: nio.Event, **fields,
    ) -> None:

        await self.register_nio_room(room)

        sender_name, sender_avatar = \
            await self.get_member_name_avatar(room.room_id, ev.sender)

        target_id = getattr(ev, "state_key", "") or ""

        target_name, target_avatar = \
            await self.get_member_name_avatar(room.room_id, target_id) \
            if target_id else ("", "")

        # Create Event ModelItem
        item = Event(
            source        = ev,
            client_id     = ev.event_id,
            event_id      = ev.event_id,
            date          = datetime.fromtimestamp(ev.server_timestamp / 1000),
            sender_id     = ev.sender,
            sender_name   = sender_name,
            sender_avatar = sender_avatar,
            target_id     = target_id,
            target_name   = target_name,
            target_avatar = target_avatar,
            **fields,
        )

        # Add the Event to model
        if ev.transaction_id in self.local_echoes_uuid:
            self.resolved_echoes[ev.event_id] = ev.transaction_id
            self.local_echoes_uuid.discard(ev.transaction_id)
            item.client_id = f"echo-{ev.transaction_id}"

        elif ev.sender in self.backend.clients:
            client = self.backend.clients[ev.sender]

            # Wait until our other account has no more pending local echoes,
            # so that we can know if this event should replace an echo
            # from that client by finding its ID in the resolved_echoes dict.
            # Server only gives back the transaction ID to the original sender.
            while client.local_echoes_uuid:  # while there are pending echoes
                await asyncio.sleep(0.1)

            with suppress(KeyError):
                item.client_id = f"echo-{client.resolved_echoes[ev.event_id]}"

        elif not await self.event_is_past(ev):
            AlertRequested()

        self.models[Event, self.user_id, room.room_id][item.client_id] = item

        await self.set_room_last_event(room.room_id, item)

        if item.sender_id == self.user_id:
            self.models[Event, self.user_id, room.room_id].sync_now()
