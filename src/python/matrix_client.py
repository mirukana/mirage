import asyncio
import html
import inspect
import json
import logging as log
import platform
from contextlib import suppress
from datetime import datetime
from enum import Enum
from functools import partial
from pathlib import Path
from types import ModuleType
from typing import DefaultDict, Dict, Optional, Set, Tuple, Type, Union
from uuid import uuid4

import nio

from . import __about__, utils
from .html_filter import HTML_FILTER
from .models.items import Account, Event, Member, Room, TypeSpecifier
from .models.model_store import ModelStore
from .pyotherside_events import AlertRequested


class UploadError(Enum):
    forbidden = "M_FORBIDDEN"
    too_large = "M_TOO_LARGE"
    unknown   = "UNKNOWN"


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

        self.past_tokens:        Dict[str, str] = {}     # {room_id: token}
        self.fully_loaded_rooms: Set[str]       = set()  # {room_id}
        self.loaded_once_rooms:  Set[str]       = set()  # {room_id}

        self.local_echoes_uuid: Set[str]       = set()
        self.resolved_echoes:   Dict[str, str] = {}  # {event_id: echo_uuid}

        self.skipped_events: DefaultDict[str, int] = DefaultDict(lambda: 0)

        self.connect_callbacks()


    def __repr__(self) -> str:
        return "%s(user_id=%r, homeserver=%r, device_id=%r)" % (
            type(self).__name__, self.user_id, self.homeserver, self.device_id,
        )


    @staticmethod
    def _classes_defined_in(module: ModuleType) -> Dict[str, Type]:
        return {
            m[0]: m[1] for m in inspect.getmembers(module, inspect.isclass)
            if not m[0].startswith("_") and
            m[1].__module__.startswith(module.__name__)
        }


    def connect_callbacks(self) -> None:
        for name, class_ in self._classes_defined_in(nio.responses).items():
            with suppress(AttributeError):
                self.add_response_callback(getattr(self, f"on{name}"), class_)

        for name, class_ in self._classes_defined_in(nio.events).items():
            with suppress(AttributeError):
                self.add_event_callback(getattr(self, f"on{name}"), class_)

        self.add_ephemeral_callback(
            self.onTypingNoticeEvent, nio.events.TypingNoticeEvent,
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
            raise RuntimeError(response)
        else:
            await self.start()


    async def resume(self, user_id: str, token: str, device_id: str) -> None:
        response = nio.LoginResponse(user_id, device_id, token)
        await self.receive_response(response)
        await self.start()


    async def logout(self) -> None:
        if self.sync_task:
            self.sync_task.cancel()
            with suppress(asyncio.CancelledError):
                await self.sync_task

        await super().logout()
        await self.close()


    async def start(self) -> None:
        def on_profile_response(future) -> None:
            resp = future.result()
            if isinstance(resp, nio.ProfileGetResponse):
                account                 = self.models[Account][self.user_id]
                account.profile_updated = datetime.now()
                account.display_name    = resp.displayname or ""
                account.avatar_url      = resp.avatar_url or ""

        ft = asyncio.ensure_future(self.backend.get_profile(self.user_id))
        ft.add_done_callback(on_profile_response)

        def on_sync_stop(future) -> None:
            if isinstance(future.exception(), BaseException):
                raise future.exception()

        self.sync_task = asyncio.ensure_future(
            self.sync_forever(timeout=10_000),
        )
        self.sync_task.add_done_callback(on_sync_stop)


    @property
    def all_rooms(self) -> Dict[str, nio.MatrixRoom]:
        return {**self.invited_rooms, **self.rooms}


    async def send_markdown(self, room_id: str, text: str) -> None:
        escape = False
        if text.startswith("//") or text.startswith(r"\/"):
            escape = True
            text   = text[1:]

        if text.startswith("/me ") and not escape:
            event_type = nio.RoomMessageEmote.__name__
            text       = text[len("/me "): ]
            content    = {"body": text, "msgtype": "m.emote"}
            to_html    = HTML_FILTER.from_markdown_inline(text, outgoing=True)
            echo_body  = HTML_FILTER.from_markdown_inline(text)
        else:
            event_type = nio.RoomMessageText.__name__
            content    = {"body": text, "msgtype": "m.text"}
            to_html    = HTML_FILTER.from_markdown(text, outgoing=True)
            echo_body  = HTML_FILTER.from_markdown(text)

        if to_html not in (html.escape(text), f"<p>{html.escape(text)}</p>"):
            content["format"]         = "org.matrix.custom.html"
            content["formatted_body"] = to_html

        uuid = str(uuid4())
        self.local_echoes_uuid.add(uuid)

        our_info = self.models[Member, room_id][self.user_id]

        local = Event(
            source           = None,
            client_id        = f"echo-{uuid}",
            event_id         = "",
            date             = datetime.now(),
            content          = echo_body,
            inline_content   = HTML_FILTER.filter_inline(echo_body),
            is_local_echo    = True,
            local_event_type = event_type,

            sender_id     = self.user_id,
            sender_name   = our_info.display_name,
            sender_avatar = our_info.avatar_url,
        )
        for user_id in self.models[Account]:
            if user_id in self.models[Member, room_id]:
                self.models[Event, user_id, room_id][f"echo-{uuid}"] = local
                self.models[Event, user_id, room_id].sync_now()

        await self.set_room_last_event(room_id, local)

        async with self.send_locks[room_id]:
            response = await self.room_send(
                room_id                   = room_id,
                message_type              = "m.room.message",
                content                   = content,
                tx_id                     = uuid,
                ignore_unverified_devices = True,
            )

            if isinstance(response, nio.RoomSendError):
                log.error("Failed to send message: %s", response)


    async def load_past_events(self, room_id: str) -> bool:
        if room_id in self.fully_loaded_rooms or room_id in self.invited_rooms:
            return False

        await self.first_sync_done.wait()

        response = await self.room_messages(
            room_id = room_id,
            start   = self.past_tokens[room_id],
            limit   = 100 if room_id in self.loaded_once_rooms else 25,
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


    async def room_forget(self, room_id: str) -> None:
        await super().room_forget(room_id)
        self.models[Room, self.user_id].pop(room_id, None)
        self.models.pop((Event, self.user_id, room_id), None)
        self.models.pop((Member, room_id), None)


    async def upload_file(self, path: Union[Path, str]) -> str:
        path = Path(path)

        with open(path, "rb") as file:
            mime = utils.guess_mime(file)
            file.seek(0, 0)

            resp = await self.upload(file, mime, path.name)

        if not isinstance(resp, nio.ErrorResponse):
            return resp.content_uri

        if resp.status_code == 403:
            return UploadError.forbidden.value

        if resp.status_code == 413:
            return UploadError.too_large.value

        return UploadError.unknown.value


    async def set_avatar_from_file(self, path: Union[Path, str],
                                  ) -> Union[bool, str]:
        resp = await self.upload_file(path)

        if resp in (i.value for i in UploadError):
            return resp

        await self.set_avatar(resp)
        return True


    async def import_keys(self, infile: str, passphrase: str) -> None:
        # Reimplemented until better solutions are worked on in nio
        await self.clear_import_error()

        loop = asyncio.get_event_loop()

        account     = self.models[Account][self.user_id]
        import_keys = partial(self.olm.import_keys_static, infile, passphrase)

        try:
            sessions = await loop.run_in_executor(None, import_keys)
        except nio.EncryptionError as err:
            account.import_error = (infile, passphrase, str(err))
            return

        account.importing_key        = 0
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
            topic          = room.topic or "",
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
            info = await self.backend.get_profile(user_id)

            return (info.displayname or "", info.avatar_url or "") \
                   if isinstance(info, nio.ProfileGetResponse) else \
                   ("", "")
        else:
            return (item.display_name, item.avatar_url)


    async def register_nio_event(
        self,
        room:           nio.MatrixRoom,
        ev:             nio.Event,
        content:        str,
        type_specifier: TypeSpecifier = TypeSpecifier.none,
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
            source         = ev,
            client_id      = ev.event_id,
            event_id       = ev.event_id,
            content        = content,
            inline_content = HTML_FILTER.filter_inline(content),
            date          = datetime.fromtimestamp(ev.server_timestamp / 1000),

            sender_id     = ev.sender,
            sender_name   = sender_name,
            sender_avatar = sender_avatar,

            type_specifier = type_specifier,

            target_id     = target_id,
            target_name   = target_name,
            target_avatar = target_avatar,
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


    # Callbacks for nio responses

    async def onSyncResponse(self, resp: nio.SyncResponse) -> None:
        for room_id, info in resp.rooms.join.items():
            if room_id not in self.past_tokens:
                self.past_tokens[room_id] = info.timeline.prev_batch

        # TODO: way of knowing if a nio.MatrixRoom is left
        for room_id, info in resp.rooms.leave.items():
            # TODO: handle in nio, these are rooms that were left before
            # starting the client.
            if room_id not in self.all_rooms:
                log.warning("Left room not in MatrixClient.rooms: %r", room_id)
                continue

            # TODO: handle left events in nio async client
            for ev in info.timeline.events:
                if isinstance(ev, nio.RoomMemberEvent):
                    await self.onRoomMemberEvent(self.all_rooms[room_id], ev)

            await self.register_nio_room(self.all_rooms[room_id], left=True)

        if not self.first_sync_done.is_set():
            asyncio.ensure_future(self.load_rooms_without_visible_events())

            self.first_sync_done.set()
            self.first_sync_date = datetime.now()
            self.models[Account][self.user_id].first_sync_done = True


    async def onErrorResponse(self, resp: nio.ErrorResponse) -> None:
        # TODO: show something in the client, must be seen on login screen too
        try:
            log.warning("%s - %s", resp, json.dumps(vars(resp), indent=4))
        except Exception:
            log.warning(repr(resp))


    # Callbacks for nio room events
    # Content: %1 is the sender, %2 the target (ev.state_key).

    async def onRoomMessageText(self, room, ev) -> None:
        co = HTML_FILTER.filter(
            ev.formatted_body
            if ev.format == "org.matrix.custom.html" else
            utils.plain2html(ev.body),
        )
        await self.register_nio_event(room, ev, content=co)


    async def onRoomMessageEmote(self, room, ev) -> None:
        co = HTML_FILTER.filter_inline(
            ev.formatted_body
            if ev.format == "org.matrix.custom.html" else
            utils.plain2html(ev.body),
        )
        await self.register_nio_event(room, ev, content=co)


    async def onRoomCreateEvent(self, room, ev) -> None:
        co = "%1 allowed users on other matrix servers to join this room." \
             if ev.federate else \
             "%1 blocked users on other matrix servers from joining this room."
        await self.register_nio_event(room, ev, content=co)


    async def onRoomGuestAccessEvent(self, room, ev) -> None:
        allowed = "allowed" if ev.guest_access else "forbad"
        co      = f"%1 {allowed} guests to join the room."
        await self.register_nio_event(room, ev, content=co)


    async def onRoomJoinRulesEvent(self, room, ev) -> None:
        access = "public" if ev.join_rule == "public" else "invite-only"
        co     = f"%1 made the room {access}."
        await self.register_nio_event(room, ev, content=co)


    async def onRoomHistoryVisibilityEvent(self, room, ev) -> None:
        if ev.history_visibility == "shared":
            to = "all room members"
        elif ev.history_visibility == "world_readable":
            to = "any member or outsider"
        elif ev.history_visibility == "joined":
            to = "all room members, since the time they joined"
        elif ev.history_visibility == "invited":
            to = "all room members, since the time they were invited"
        else:
            to = "???"
            log.warning("Invalid visibility - %s",
                        json.dumps(vars(ev), indent=4))

        co = f"%1 made future room history visible to {to}."
        await self.register_nio_event(room, ev, content=co)


    async def onPowerLevelsEvent(self, room, ev) -> None:
        co = "%1 changed the room's permissions."  # TODO: improve
        await self.register_nio_event(room, ev, content=co)


    async def process_room_member_event(
        self, room, ev,
    ) -> Optional[Tuple[TypeSpecifier, str]]:

        if ev.prev_content == ev.content:
            return None

        prev            = ev.prev_content
        now             = ev.content
        membership      = ev.membership
        prev_membership = ev.prev_membership
        ev_date         = datetime.fromtimestamp(ev.server_timestamp / 1000)

        member_change = TypeSpecifier.membership_change

        # Membership changes
        if not prev or membership != prev_membership:
            reason = f" Reason: {now['reason']}" if now.get("reason") else ""

            if membership == "join":
                return (
                    member_change,
                    "%1 accepted their invitation."
                    if prev and prev_membership == "invite" else
                    "%1 joined the room.",
                )

            if membership == "invite":
                return (member_change, "%1 invited %2 to the room.")

            if membership == "leave":
                if ev.state_key == ev.sender:
                    return (
                        member_change,
                        f"%1 declined their invitation.{reason}"
                        if prev and prev_membership == "invite" else
                        f"%1 left the room.{reason}",
                    )

                return (
                    member_change,

                    f"%1 withdrew %2's invitation.{reason}"
                    if prev and prev_membership == "invite" else

                    f"%1 unbanned %2 from the room.{reason}"
                    if prev and prev_membership == "ban" else

                    f"%1 kicked out %2 from the room.{reason}",
                )

            if membership == "ban":
                return (member_change, f"%1 banned %2 from the room.{reason}")

        # Profile changes
        changed = []

        if prev and now["avatar_url"] != prev["avatar_url"]:
            changed.append("profile picture")  # TODO: <img>s

        if prev and now["displayname"] != prev["displayname"]:
            changed.append('display name from "{}" to "{}"'.format(
                prev["displayname"] or ev.state_key,
                now["displayname"] or ev.state_key,
            ))

        if changed:
            # Update our account profile if the event is newer than last update
            if ev.state_key == self.user_id:
                account = self.models[Account][self.user_id]
                updated = account.profile_updated

                if not updated or updated < ev_date:
                    account.profile_updated = ev_date
                    account.display_name    = now["displayname"] or ""
                    account.avatar_url      = now["avatar_url"] or ""

            # Hide profile events from the timeline - XXX
            self.skipped_events[room.room_id] += 1
            return None

            return (
                TypeSpecifier.profile_change,
                "%1 changed their {}.".format(" and ".join(changed)),
            )

        log.warning("Unknown member event: %s", json.dumps(vars(ev), indent=4))
        return None


    async def onRoomMemberEvent(self, room, ev) -> None:
        type_and_content = await self.process_room_member_event(room, ev)

        if type_and_content is None:
            # This is run from register_nio_event otherwise
            await self.register_nio_room(room)
        else:
            type_specifier, content = type_and_content
            await self.register_nio_event(
                room, ev, content=content, type_specifier=type_specifier,
            )


    async def onRoomAliasEvent(self, room, ev) -> None:
        co = f"%1 set the room's main address to {ev.canonical_alias}."
        await self.register_nio_event(room, ev, content=co)


    async def onRoomNameEvent(self, room, ev) -> None:
        co = f"%1 changed the room's name to \"{ev.name}\"."
        await self.register_nio_event(room, ev, content=co)


    async def onRoomTopicEvent(self, room, ev) -> None:
        co = f"%1 changed the room's topic to \"{ev.topic}\"."
        await self.register_nio_event(room, ev, content=co)


    async def onRoomEncryptionEvent(self, room, ev) -> None:
        co = "%1 turned on encryption for this room."
        await self.register_nio_event(room, ev, content=co)


    async def onMegolmEvent(self, room, ev) -> None:
        co = "%1 sent an undecryptable message."
        await self.register_nio_event(room, ev, content=co)


    async def onBadEvent(self, room, ev) -> None:
        co = "%1 sent a malformed event."
        await self.register_nio_event(room, ev, content=co)


    async def onUnknownBadEvent(self, room, ev) -> None:
        co = "%1 sent an event this client doesn't understand."
        await self.register_nio_event(room, ev, content=co)


    # Callbacks for nio invite events

    async def onInviteEvent(self, room, ev) -> None:
        await self.register_nio_room(room)


    # Callbacks for nio ephemeral events

    async def onTypingNoticeEvent(self, room, ev) -> None:
        # Prevent recent past typing notices from being shown for a split
        # second on client startup:
        if not self.first_sync_done.is_set():
            return

        self.models[Room, self.user_id][room.room_id].typing_members = sorted(
            room.user_name(user_id) for user_id in ev.users
            if user_id not in self.backend.clients
        )
