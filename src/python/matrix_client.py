import asyncio
import html
import inspect
import json
import logging as log
import platform
from contextlib import suppress
from datetime import datetime
from types import ModuleType
from typing import DefaultDict, Dict, Optional, Type
from uuid import uuid4

import nio
from nio.rooms import MatrixRoom

from . import __about__
from .events import rooms, users
from .events.rooms import TimelineEventReceived, TimelineMessageReceived
from .html_filter import HTML_FILTER


class MatrixClient(nio.AsyncClient):
    def __init__(self,
                 backend,
                 user:       str,
                 homeserver: str           = "https://matrix.org",
                 device_id:  Optional[str] = None) -> None:
        # TODO: ensure homeserver starts with a scheme://

        from .backend import Backend
        self.backend: Backend = backend

        self.sync_task: Optional[asyncio.Future] = None

        self.send_locks: DefaultDict[str, asyncio.Lock] = \
                DefaultDict(asyncio.Lock)  # {room_id: lock}

        super().__init__(homeserver=homeserver, user=user, device_id=device_id)

        self.connect_callbacks()


    def __repr__(self) -> str:
        return "%s(user_id=%r, homeserver=%r, device_id=%r)" % (
            type(self).__name__, self.user_id, self.homeserver, self.device_id
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


    async def start_syncing(self) -> None:
        self.sync_task = asyncio.ensure_future(
            self.sync_forever(timeout=10_000)
        )

        def callback(task):
            raise task.exception()

        self.sync_task.add_done_callback(callback)


    @property
    def default_device_name(self) -> str:
        os_ = f" on {platform.system()}".rstrip()
        os_ = f"{os_} {platform.release()}".rstrip() if os_ != " on" else ""
        return f"{__about__.__pretty_name__}{os_}"


    async def login(self, password: str, device_name: str = "") -> None:
        response = await super().login(
            password, device_name or self.default_device_name
        )

        if isinstance(response, nio.LoginError):
            print(response)
        else:
            await self.start_syncing()


    async def resume(self, user_id: str, token: str, device_id: str) -> None:
        response = nio.LoginResponse(user_id, device_id, token)
        await self.receive_response(response)
        await self.start_syncing()


    async def logout(self) -> None:
        if self.sync_task:
            self.sync_task.cancel()
            with suppress(asyncio.CancelledError):
                await self.sync_task

        await self.close()


    async def request_user_update_event(self, user_id: str) -> None:
        if user_id in self.backend.pending_profile_requests:
            return
        self.backend.pending_profile_requests.add(user_id)

        print("Requesting user profile:", user_id)
        response = await self.get_profile(user_id)

        if isinstance(response, nio.ProfileGetError):
            log.warning("%s: %s", user_id, response)

        users.UserUpdated(
            user_id        = user_id,
            display_name   = getattr(response, "displayname", "") or "",
            avatar_url     = getattr(response, "avatar_url", "") or "",
            status_message = "",  # TODO
        )

        self.backend.pending_profile_requests.discard(user_id)


    @property
    def all_rooms(self) -> Dict[str, MatrixRoom]:
        return {**self.invited_rooms, **self.rooms}


    async def send_markdown(self, room_id: str, text: str) -> None:
        content = {
            "body":           text,
            "formatted_body": HTML_FILTER.from_markdown(text),
            "format":         "org.matrix.custom.html",
            "msgtype":        "m.text",
        }

        TimelineMessageReceived(
            event_type    = nio.RoomMessageText,
            room_id       = room_id,
            event_id      = f"local_echo.{uuid4()}",
            sender_id     = self.user_id,
            date          = datetime.now(),
            content       = content["formatted_body"],
            is_local_echo = True,
        )

        async with self.send_locks[room_id]:
            response = await self.room_send(room_id, "m.room.message", content)

            if isinstance(response, nio.RoomSendError):
                log.error("Failed to send message: %s", response)


    async def load_past_events(self, room_id: str, limit: int = 25) -> bool:
        if room_id in self.backend.fully_loaded_rooms:
            return False

        response = await self.room_messages(
            room_id = room_id,
            start   = self.backend.past_tokens[room_id],
            limit   = limit,
        )

        more_to_load = True
        print(len(response.chunk))

        if self.backend.past_tokens[room_id] == response.end:
            self.backend.fully_loaded_rooms.add(room_id)
            more_to_load = False

        self.backend.past_tokens[room_id] = response.end

        for event in response.chunk:
            for cb in self.event_callbacks:
                if (cb.filter is None or isinstance(event, cb.filter)):
                    await cb.func(
                        self.all_rooms[room_id], event, from_past=True
                    )

        return more_to_load


    # Callbacks for nio responses

    async def onSyncResponse(self, resp: nio.SyncResponse) -> None:
        up = rooms.RoomUpdated.from_nio

        for room_id, info in resp.rooms.invite.items():
            up(self.user_id, "Invites", self.invited_rooms[room_id], info)

        for room_id, info in resp.rooms.join.items():
            if room_id not in self.backend.past_tokens:
                self.backend.past_tokens[room_id] = info.timeline.prev_batch

            up(self.user_id, "Rooms", self.rooms[room_id], info)

        for room_id, info in resp.rooms.leave.items():
            # TODO: handle in nio, these are rooms that were left before
            # starting the client.
            if room_id not in self.rooms:
                continue

            # TODO: handle left events in nio async client
            for ev in info.timeline.events:
                if isinstance(ev, nio.RoomMemberEvent):
                    await self.onRoomMemberEvent(self.rooms[room_id], ev)

            up(self.user_id, "Left", self.rooms[room_id], info)


    async def onErrorResponse(self, resp: nio.ErrorResponse) -> None:
        # TODO: show something in the client
        log.warning(resp)


    # Callbacks for nio events

    # Special %tokens for event contents:
    # %S = sender's displayname
    # %T = target (ev.state_key)'s displayname
    # pylint: disable=unused-argument

    async def onRoomMessageText(self, room, ev, from_past=False) -> None:
        co = HTML_FILTER.filter(
            ev.formatted_body
            if ev.format == "org.matrix.custom.html" else html.escape(ev.body)
        )

        TimelineMessageReceived.from_nio(room, ev, content=co)


    async def onRoomCreateEvent(self, room, ev, from_past=False) -> None:
        co = "%S allowed users on other matrix servers to join this room." \
             if ev.federate else \
             "%S blocked users on other matrix servers from joining this room."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onRoomGuestAccessEvent(self, room, ev, from_past=False) -> None:
        allowed = "allowed" if ev.guest_access else "forbad"
        co      = f"%S {allowed} guests to join the room."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onRoomJoinRulesEvent(self, room, ev, from_past=False) -> None:
        access = "public" if ev.join_rule == "public" else "invite-only"
        co     = f"%S made the room {access}."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onRoomHistoryVisibilityEvent(self, room, ev, from_past=False
                                          ) -> None:
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
                        json.dumps(ev.__dict__, indent=4))

        co = f"%S made future room history visible to {to}."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onPowerLevelsEvent(self, room, ev, from_past=False) -> None:
        co = "%S changed the room's permissions."  # TODO: improve
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def get_room_member_event_content(self, ev) -> Optional[str]:
        prev            = ev.prev_content
        now             = ev.content
        membership      = ev.membership
        prev_membership = ev.prev_membership

        if not prev or membership != prev_membership:
            reason = f" Reason: {now['reason']}" if now.get("reason") else ""

            if membership == "join":
                did = "accepted" if prev and prev_membership == "invite" else \
                      "declined"
                return f"%S {did} their invitation."

            if membership == "invite":
                return f"%S invited %T to the room."

            if membership == "leave":
                if ev.state_key == ev.sender:
                    return (
                        f"%S declined their invitation.{reason}"
                        if prev and prev_membership == "invite" else
                        f"%S left the room.{reason}"
                    )

                return (
                    f"%S withdrew %T's invitation.{reason}"
                    if prev and prev_membership == "invite" else

                    f"%S unbanned %T from the room.{reason}"
                    if prev and prev_membership == "ban" else

                    f"%S kicked out %T from the room.{reason}"
                )

            if membership == "ban":
                return f"%S banned %T from the room.{reason}"


        if ev.sender in self.backend.clients:
            # Don't put our own name/avatar changes in the timeline
            return None

        changed = []

        if prev and now["avatar_url"] != prev["avatar_url"]:
            changed.append("profile picture")  # TODO: <img>s


        if prev and now["displayname"] != prev["displayname"]:
            changed.append('display name from "{}" to "{}"'.format(
                prev["displayname"] or ev.state_key,
                now["displayname"] or ev.state_key,
            ))

        if changed:
            return "%S changed their {}.".format(" and ".join(changed))

        log.warning("Invalid member event - %s",
                    json.dumps(ev.__dict__, indent=4))
        return None


    async def onRoomMemberEvent(self, room, ev, from_past=False) -> None:
        if not from_past and ev.membership != "leave":
            users.UserUpdated(
                user_id        = ev.state_key,
                display_name   = ev.content["displayname"] or "",
                avatar_url     = ev.content["avatar_url"] or "",
                status_message = "",  # TODO
            )

        co = await self.get_room_member_event_content(ev)

        if co is not None:
            TimelineEventReceived.from_nio(room, ev, content=co)


    async def onRoomAliasEvent(self, room, ev, from_past=False) -> None:
        co = f"%S set the room's main address to {ev.canonical_alias}."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onRoomNameEvent(self, room, ev, from_past=False) -> None:
        co = f"%S changed the room's name to \"{ev.name}\"."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onRoomTopicEvent(self, room, ev, from_past=False) -> None:
        co = f"%S changed the room's topic to \"{ev.topic}\"."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onRoomEncryptionEvent(self, room, ev, from_past=False) -> None:
        co = f"%S turned on encryption for this room."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onOlmEvent(self, room, ev, from_past=False) -> None:
        co = f"%S hasn't sent your device the keys to decrypt this message."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onMegolmEvent(self, room, ev, from_past=False) -> None:
        await self.onOlmEvent(room, ev, from_past=False)


    async def onBadEvent(self, room, ev, from_past=False) -> None:
        co = f"%S sent a malformed event."
        TimelineEventReceived.from_nio(room, ev, content=co)


    async def onUnknownBadEvent(self, room, ev, from_past=False) -> None:
        co = f"%S sent an event this client doesn't understand."
        TimelineEventReceived.from_nio(room, ev, content=co)
