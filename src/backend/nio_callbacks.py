# SPDX-License-Identifier: LGPL-3.0-or-later

import json
import logging as log
from contextlib import suppress
from dataclasses import dataclass, field
from datetime import datetime
from typing import TYPE_CHECKING, Optional, Tuple
from urllib.parse import quote

import nio

from . import utils
from .html_markdown import HTML_PROCESSOR
from .models.items import TypeSpecifier

if TYPE_CHECKING:
    from .matrix_client import MatrixClient


@dataclass
class NioCallbacks:
    """Register callbacks for nio's request responses and room events.

    For every nio `Response` and `Event` subclasses, this class can have a
    method named `on<ClassName>` (e.g. `onRoomMessageText`) that will
    automatically be registered in nio.

    For room event content strings, the `%1` and `%2` placeholders
    refer to the event's sender and who this event targets (`state_key`) or
    the redactor of this event.
    These are processed from QML, to allow for future translations of
    the strings.
    """

    client: "MatrixClient" = field()

    def __post_init__(self) -> None:
        """Register our methods as callbacks."""

        for name, class_ in utils.classes_defined_in(nio.responses).items():
            with suppress(AttributeError):
                method = getattr(self, f"on{name}")
                self.client.add_response_callback(method, class_)

        for name, class_ in utils.classes_defined_in(nio.events).items():
            with suppress(AttributeError):
                method = getattr(self, f"on{name}")
                self.client.add_event_callback(method, class_)

        self.client.add_ephemeral_callback(
            self.onTypingNoticeEvent, nio.events.TypingNoticeEvent,
        )


    # Response callbacks

    async def onSyncResponse(self, resp: nio.SyncResponse) -> None:
        room_model = self.client.models[self.client.user_id, "rooms"]

        for room_id, info in resp.rooms.join.items():
            if room_id not in room_model:
                # Just in case we don't get any events for that room that
                # triggers other callbacks
                await self.client.register_nio_room(self.client.rooms[room_id])

            if room_id not in self.client.past_tokens:
                self.client.past_tokens[room_id] = info.timeline.prev_batch

        # TODO: way of knowing if a nio.MatrixRoom is left
        for room_id, info in resp.rooms.leave.items():
            # TODO: handle in nio, these are rooms that were left before
            # starting the client.
            if room_id not in self.client.all_rooms:
                continue

            # TODO: handle left events in nio async client
            for ev in info.timeline.events:
                if isinstance(ev, nio.RoomMemberEvent):
                    await self.onRoomMemberEvent(
                        self.client.all_rooms[room_id], ev,
                    )

            await self.client.register_nio_room(
                self.client.all_rooms[room_id], left=True,
            )

        if not self.client.first_sync_done.is_set():
            self.client.first_sync_done.set()
            self.client.first_sync_date = datetime.now()

            account = self.client.models["accounts"][self.client.user_id]
            account.first_sync_done = True


    # Event callbacks

    async def onRoomMessageText(self, room, ev) -> None:
        co = HTML_PROCESSOR.filter(
            ev.formatted_body
            if ev.format == "org.matrix.custom.html" else
            utils.plain2html(ev.body),

            room_id = room.room_id,
        )

        mention_list = HTML_PROCESSOR.mentions_in_html(co)

        await self.client.register_nio_event(
            room, ev, content=co, mentions=mention_list,
        )


    async def onRoomMessageNotice(self, room, ev) -> None:
        await self.onRoomMessageText(room, ev)


    async def onRoomMessageEmote(self, room, ev) -> None:
        await self.onRoomMessageText(room, ev)


    async def onRoomMessageUnknown(self, room, ev) -> None:
        co = f"%1 sent an unsupported <b>{ev.msgtype}</b> message"
        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomMessageMedia(self, room, ev) -> None:
        info             = ev.source["content"].get("info", {})
        media_crypt_dict = ev.source["content"].get("file", {})
        thumb_info       = info.get("thumbnail_info", {})
        thumb_crypt_dict = info.get("thumbnail_file", {})

        await self.client.register_nio_event(
            room,
            ev,
            content        = "",
            inline_content = ev.body,

            media_url        = ev.url,
            media_title      = ev.body,
            media_width      = info.get("w") or 0,
            media_height     = info.get("h") or 0,
            media_duration   = info.get("duration") or 0,
            media_size       = info.get("size") or 0,
            media_mime       = info.get("mimetype") or 0,
            media_crypt_dict = media_crypt_dict,

            thumbnail_url =
                info.get("thumbnail_url") or thumb_crypt_dict.get("url") or "",

            thumbnail_width      = thumb_info.get("w") or 0,
            thumbnail_height     = thumb_info.get("h") or 0,
            thumbnail_mime       = thumb_info.get("mimetype") or "",
            thumbnail_crypt_dict = thumb_crypt_dict,
        )


    async def onRoomEncryptedMedia(self, room, ev) -> None:
        await self.onRoomMessageMedia(room, ev)


    async def onRedactionEvent(self, room, ev) -> None:
        model = self.client.models[self.client.user_id, room.room_id, "events"]
        event = None

        for existing in model._sorted_data:
            if existing.event_id == ev.redacts:
                event = existing
                break

        if not (
            event and
            (event.event_type is not nio.RedactedEvent or event.is_local_echo)
        ):
            await self.client.register_nio_room(room)
            return

        event.source.source["content"]  = {}
        event.source.source["unsigned"] = {
            "redacted_by":      ev.event_id,
            "redacted_because": ev.source,
        }

        await self.onRedactedEvent(
            room,
            nio.RedactedEvent.from_dict(event.source.source),
            event_id = event.id,
        )


    async def onRedactedEvent(self, room, ev, event_id: str = "") -> None:
        await self.client.register_nio_event(
            room,
            ev,
            event_id = event_id,
            reason   = ev.reason or "",

            content = await self.client.get_redacted_event_content(
                type(ev), ev.redacter, ev.sender, ev.reason,
            ),

            redacter_id   = ev.redacter or "",
            redacter_name =
                (await self.client.get_member_name_avatar(
                    room.room_id, ev.redacter,
                ))[0] if ev.redacter else "",
        )


    async def onRoomCreateEvent(self, room, ev) -> None:
        co = "%1 allowed users on other matrix servers to join this room" \
             if ev.federate else \
             "%1 blocked users on other matrix servers from joining this room"
        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomGuestAccessEvent(self, room, ev) -> None:
        allowed = "allowed" if ev.guest_access else "forbad"
        co      = f"%1 {allowed} guests to join the room"
        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomJoinRulesEvent(self, room, ev) -> None:
        access = "public" if ev.join_rule == "public" else "invite-only"
        co     = f"%1 made the room {access}"
        await self.client.register_nio_event(room, ev, content=co)


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

        co = f"%1 made future room history visible to {to}"
        await self.client.register_nio_event(room, ev, content=co)


    async def onPowerLevelsEvent(self, room, ev) -> None:
        co = "%1 changed the room's permissions"  # TODO: improve
        await self.client.register_nio_event(room, ev, content=co)


    async def process_room_member_event(
        self, room: nio.MatrixRoom, ev: nio.RoomMemberEvent,
    ) -> Optional[Tuple[TypeSpecifier, str]]:
        """Return a `TypeSpecifier` and string describing a member event.

        Matrix member events can represent many actions:
        a user joined the room, a user banned another, a user changed their
        display name, etc.
        """
        if ev.prev_content == ev.content:
            return None

        prev            = ev.prev_content
        now             = ev.content
        membership      = ev.membership
        prev_membership = ev.prev_membership
        ev_date         = datetime.fromtimestamp(ev.server_timestamp / 1000)

        member_change = TypeSpecifier.MembershipChange

        # Membership changes
        if not prev or membership != prev_membership:
            if self.client.backend.ui_settings["hideMembershipEvents"]:
                return None

            reason = f", reason: {now['reason']}" if now.get("reason") else ""

            if membership == "join":
                return (
                    member_change,
                    "%1 accepted their invitation"
                    if prev and prev_membership == "invite" else
                    "%1 joined the room",
                )

            if membership == "invite":
                return (member_change, "%1 invited %2 to the room")

            if membership == "leave":
                if ev.state_key == ev.sender:
                    return (
                        member_change,
                        f"%1 declined their invitation{reason}"
                        if prev and prev_membership == "invite" else
                        f"%1 left the room{reason}",
                    )

                return (
                    member_change,

                    f"%1 withdrew %2's invitation{reason}"
                    if prev and prev_membership == "invite" else

                    f"%1 unbanned %2 from the room{reason}"
                    if prev and prev_membership == "ban" else

                    f"%1 kicked %2 out from the room{reason}",
                )

            if membership == "ban":
                return (member_change, f"%1 banned %2 from the room{reason}")

        # Profile changes
        changed = []

        if prev and now.get("avatar_url") != prev.get("avatar_url"):
            changed.append("profile picture")  # TODO: <img>s

        if prev and now.get("displayname") != prev.get("displayname"):
            changed.append('display name from "{}" to "{}"'.format(
                prev.get("displayname") or ev.state_key,
                now.get("displayname") or ev.state_key,
            ))

        if changed:
            # Update our account profile if the event is newer than last update
            if ev.state_key == self.client.user_id:
                account = self.client.models["accounts"][self.client.user_id]

                if account.profile_updated < ev_date:
                    account.profile_updated = ev_date
                    account.display_name    = now.get("displayname") or ""
                    account.avatar_url      = now.get("avatar_url") or ""

            if self.client.backend.ui_settings["hideProfileChangeEvents"]:
                return None

            return (
                TypeSpecifier.ProfileChange,
                "%1 changed their {}".format(" and ".join(changed)),
            )

        log.warning("Unknown member event: %s", json.dumps(vars(ev), indent=4))
        return None


    async def onRoomMemberEvent(self, room, ev) -> None:
        type_and_content = await self.process_room_member_event(room, ev)

        if type_and_content is not None:
            type_specifier, content = type_and_content

            await self.client.register_nio_event(
                room, ev, content=content, type_specifier=type_specifier,
            )
        else:
            # Normally, register_nio_event() will call register_nio_room().
            # but in this case we don't have any event we want to register.
            await self.client.register_nio_room(room)


    async def onRoomAliasEvent(self, room, ev) -> None:
        if ev.canonical_alias:
            url  = f"https://matrix.to/#/{quote(ev.canonical_alias)}"
            link = f"<a href='{url}'>{ev.canonical_alias}</a>"
            co   = f"%1 set the room's main address to {link}"
        else:
            co = "%1 removed the room's main address"

        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomNameEvent(self, room, ev) -> None:
        if ev.name:
            co = f"%1 changed the room's name to \"{ev.name}\""
        else:
            co = "%1 removed the room's name"

        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomAvatarEvent(self, room, ev) -> None:
        if ev.avatar_url:
            co = "%1 changed the room's picture"
        else:
            co = "%1 removed the room's picture"

        await self.client.register_nio_event(
            room, ev, content=co, media_url=ev.avatar_url,
        )


    async def onRoomTopicEvent(self, room, ev) -> None:
        if ev.topic:
            topic = HTML_PROCESSOR.filter(
                ev.topic, inline=True, room_id=room.room_id,
            )
            co = f"%1 changed the room's topic to \"{topic}\""
        else:
            co = "%1 removed the room's topic"

        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomEncryptionEvent(self, room, ev) -> None:
        co = "%1 turned on encryption for this room"
        await self.client.register_nio_event(room, ev, content=co)


    async def onMegolmEvent(self, room, ev) -> None:
        co = "%1 sent an undecryptable message"
        await self.client.register_nio_event(room, ev, content=co)


    async def onBadEvent(self, room, ev) -> None:
        co = f"%1 sent a malformed <b>{ev.type}</b> event"
        await self.client.register_nio_event(room, ev, content=co)


    async def onUnknownBadEvent(self, room, ev) -> None:
        co = "%1 sent a malformed event lacking a minimal structure"
        await self.client.register_nio_event(room, ev, content=co)


    async def onUnknownEvent(self, room, ev) -> None:
        if self.client.backend.ui_settings["hideUnknownEvents"]:
            return

        co = f"%1 sent an unsupported <b>{ev.type}</b> event"
        await self.client.register_nio_event(room, ev, content=co)


    async def onUnknownEncryptedEvent(self, room, ev) -> None:
        co = (
            f"%1 sent an <b>{ev.type}</b> event encrypted with "
            f"unsupported <b>{ev.algorithm}</b> algorithm"
        )
        await self.client.register_nio_event(room, ev, content=co)


    async def onInviteEvent(self, room, ev) -> None:
        await self.client.register_nio_room(room)


    async def onTypingNoticeEvent(self, room, ev) -> None:
        # Prevent recent past typing notices from being shown for a split
        # second on client startup:
        if not self.client.first_sync_done.is_set():
            return

        await self.client.register_nio_room(room)

        room_id = room.room_id

        room_item = self.client.models[self.client.user_id, "rooms"][room_id]

        room_item.typing_members = sorted(
            room.user_name(user_id) or user_id for user_id in ev.users
            if user_id not in self.client.backend.clients
        )
