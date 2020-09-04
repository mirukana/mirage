# SPDX-License-Identifier: LGPL-3.0-or-later

import asyncio
import json
import logging as log
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from html import escape
from pathlib import Path
from typing import TYPE_CHECKING, Dict, List, Optional, Tuple, Union
from urllib.parse import quote

import nio

from .html_markdown import HTML_PROCESSOR
from .media_cache import Media
from .models.items import TypeSpecifier
from .presence import Presence
from .pyotherside_events import DevicesUpdated
from .utils import classes_defined_in, plain2html

if TYPE_CHECKING:
    from .matrix_client import MatrixClient


@dataclass
class NioCallbacks:
    """Register callbacks for nio's request responses and events.

    For every class defined in the `nio.responses` and `nio.events` modules,
    this class can have a method named
    `on<ClassName>` (e.g. `onRoomMessageText`) that will
    automatically be registered in the `client`'s callbacks.

    For room event content strings, the `%1` and `%2` placeholders
    refer to the event's sender and who this event targets (`state_key`) or
    the redactor of this event.
    These are processed from QML, to allow for future translations of
    the strings.
    """

    client: "MatrixClient" = field()

    def __post_init__(self) -> None:
        """Register our methods as callbacks."""

        self.models = self.client.models

        for name, response_class in classes_defined_in(nio.responses).items():
            method = getattr(self, f"on{name}", None)

            if method:
                self.client.add_response_callback(method, response_class)

        for name, event_class in classes_defined_in(nio.events).items():
            method = getattr(self, f"on{name}", None)

            if not method:
                continue

            if issubclass(event_class, nio.EphemeralEvent):
                self.client.add_ephemeral_callback(method, event_class)
            elif issubclass(event_class, nio.ToDeviceEvent):
                self.client.add_to_device_callback(method, event_class)
            elif issubclass(event_class, nio.AccountDataEvent):
                self.client.add_room_account_data_callback(method, event_class)
            elif issubclass(event_class, nio.PresenceEvent):
                self.client.add_presence_callback(method, event_class)
            else:
                self.client.add_event_callback(method, event_class)


    @property
    def user_id(self) -> str:
        return self.client.user_id


    # Response callbacks

    async def onSyncResponse(self, resp: nio.SyncResponse) -> None:
        for room_id in resp.rooms.invite:
            await self.client.register_nio_room(self.client.all_rooms[room_id])

        for room_id, info in resp.rooms.join.items():
            await self.client.register_nio_room(self.client.rooms[room_id])

            if room_id not in self.client.past_tokens:
                self.client.past_tokens[room_id] = info.timeline.prev_batch

            for ev in info.state:
                if isinstance(ev, nio.PowerLevelsEvent):
                    stored = self.client.power_level_events.get(room_id)
                    time   = ev.server_timestamp

                    if not stored or time > stored.server_timestamp:
                        self.client.power_level_events[room_id] = ev

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

        account            = self.models["accounts"][self.user_id]
        account.connecting = False

        if not self.client.first_sync_done.is_set():
            self.client.first_sync_done.set()
            self.client.first_sync_date = datetime.now()


    async def onKeysQueryResponse(self, resp: nio.KeysQueryResponse) -> None:
        refresh_rooms = {}
        clients       = self.client.backend.clients

        for user_id in resp.changed:
            for room in self.client.rooms.values():
                if user_id in room.users:
                    refresh_rooms[room.room_id] = room

            if user_id != self.user_id and user_id in clients:
                await self.client.auto_verify_account(clients[user_id])

        for room_id, room in refresh_rooms.items():
            room_item = self.models[self.user_id, "rooms"].get(room_id)

            if room_item:
                room_item.unverified_devices = \
                    self.client.room_contains_unverified(room_id)
            else:
                await self.client.register_nio_room(room)

        DevicesUpdated(self.user_id)


    # Room events, invite events and misc events callbacks

    async def onRoomMessageText(
        self, room: nio.MatrixRoom, ev: nio.RoomMessageText,
    ) -> None:
        co = HTML_PROCESSOR.filter(
            ev.formatted_body
            if ev.format == "org.matrix.custom.html" else
            plain2html(ev.body),
        )

        mention_list = HTML_PROCESSOR.mentions_in_html(co)

        await self.client.register_nio_event(
            room, ev, content=co, mentions=mention_list,
        )


    async def onRoomMessageNotice(
        self, room: nio.MatrixRoom, ev: nio.RoomMessageNotice,
    ) -> None:
        await self.onRoomMessageText(room, ev)


    async def onRoomMessageEmote(
        self, room: nio.MatrixRoom, ev: nio.RoomMessageEmote,
    ) -> None:
        await self.onRoomMessageText(room, ev)


    async def onRoomMessageUnknown(
        self, room: nio.MatrixRoom, ev: nio.RoomMessageUnknown,
    ) -> None:
        co = f"%1 sent an unsupported <b>{escape(ev.msgtype)}</b> message"
        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomMessageMedia(
        self, room: nio.MatrixRoom, ev: nio.RoomMessageMedia,
    ) -> None:
        info             = ev.source["content"].get("info", {})
        media_crypt_dict = ev.source["content"].get("file", {})
        thumb_info       = info.get("thumbnail_info", {})
        thumb_crypt_dict = info.get("thumbnail_file", {})

        try:
            media_local_path: Union[Path, str] = await Media(
                cache          = self.client.backend.media_cache,
                client_user_id = self.user_id,
                mxc            = ev.url,
                title          = ev.body,
                crypt_dict     = media_crypt_dict,
            ).get_local()
        except FileNotFoundError:
            media_local_path = ""

        item = await self.client.register_nio_event(
            room,
            ev,
            content        = "",
            inline_content = ev.body,

            media_url        = ev.url,
            media_http_url   = await self.client.mxc_to_http(ev.url),
            media_title      = ev.body,
            media_width      = info.get("w") or 0,
            media_height     = info.get("h") or 0,
            media_duration   = info.get("duration") or 0,
            media_size       = info.get("size") or 0,
            media_mime       = info.get("mimetype") or "",
            media_crypt_dict = media_crypt_dict,
            media_local_path = media_local_path,

            thumbnail_url =
                info.get("thumbnail_url") or thumb_crypt_dict.get("url") or "",

            thumbnail_width      = thumb_info.get("w") or 0,
            thumbnail_height     = thumb_info.get("h") or 0,
            thumbnail_mime       = thumb_info.get("mimetype") or "",
            thumbnail_crypt_dict = thumb_crypt_dict,
        )

        self.client.backend.mxc_events[ev.url].append(item)


    async def onRoomEncryptedMedia(
        self, room: nio.MatrixRoom, ev: nio.RoomEncryptedMedia,
    ) -> None:
        await self.onRoomMessageMedia(room, ev)


    async def onRedactionEvent(
        self, room: nio.MatrixRoom, ev: nio.RedactionEvent,
    ) -> None:
        model = self.models[self.user_id, room.room_id, "events"]
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


    async def onRedactedEvent(
        self, room: nio.MatrixRoom, ev: nio.RedactedEvent, event_id: str = "",
    ) -> None:
        redacter_name, _, must_fetch_redacter = \
            await self.client.get_member_profile(room.room_id, ev.redacter) \
            if ev.redacter else ("", "", False)

        await self.client.register_nio_event(
            room,
            ev,
            event_id = event_id,
            reason   = ev.reason or "",

            content = await self.client.get_redacted_event_content(
                type(ev), ev.redacter, ev.sender, ev.reason,
            ),

            mentions               = [],
            type_specifier         = TypeSpecifier.Unset,
            media_url              = "",
            media_http_url         = "",
            media_title            = "",
            media_local_path       = "",
            thumbnail_url          = "",
            redacter_id            = ev.redacter or "",
            redacter_name          = redacter_name,
            override_fetch_profile = True,
        )


    async def onRoomCreateEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomCreateEvent,
    ) -> None:
        co = "%1 allowed users on other matrix servers to join this room" \
             if ev.federate else \
             "%1 blocked users on other matrix servers from joining this room"
        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomGuestAccessEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomGuestAccessEvent,
    ) -> None:
        allowed = "allowed" if ev.guest_access == "can_join" else "forbad"
        co      = f"%1 {allowed} guests to join the room"
        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomJoinRulesEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomJoinRulesEvent,
    ) -> None:
        access = "public" if ev.join_rule == "public" else "invite-only"
        co     = f"%1 made the room {access}"
        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomHistoryVisibilityEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomHistoryVisibilityEvent,
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
                        json.dumps(vars(ev), indent=4))

        co = f"%1 made future room history visible to {to}"
        await self.client.register_nio_event(room, ev, content=co)


    async def onPowerLevelsEvent(
        self, room: nio.MatrixRoom, ev: nio.PowerLevelsEvent,
    ) -> None:
        levels = ev.power_levels
        stored = self.client.power_level_events.get(room.room_id)

        if not stored or ev.server_timestamp > stored.server_timestamp:
            self.client.power_level_events[room.room_id] = ev

        try:
            previous = ev.source["unsigned"]["prev_content"]
        except KeyError:
            previous = {}

        users_previous  = previous.get("users", {})
        events_previous = previous.get("events", {})

        # Update room members who had their power level changed

        for user_id, level in levels.users.items():
            if user_id in room.users and level != users_previous.get(user_id):
                await self.client.add_member(room, user_id)

        # Event formatting

        changes:       List[Tuple[str, int, int]] = []
        event_changes: List[Tuple[str, int, int]] = []
        user_changes:  List[Tuple[str, int, int]] = []

        def lvl(level: int) -> str:
            return (
                f"Admin ({level})"     if level == 100  else
                f"Moderator ({level})" if level >= 50 else
                f"User ({level})"
            )

        def format_defaults_dict(
            levels:   Dict[str, Union[int, dict]],
            previous: Dict[str, Union[int, dict]],
            prefix:   str             = "",
        ) -> None:
            for name, level in levels.items():
                if not prefix and name in ("users", "events"):
                    continue

                if isinstance(level, dict):
                    prev = previous.get(name, {})

                    if not isinstance(prev, dict):
                        prev = {}

                    format_defaults_dict(level, prev, f"{prefix}{name}.")
                    continue

                default_0 = ("users_default", "events_default", "invite")
                old       = previous.get(
                    name, 0 if not prefix and name in default_0 else 50,
                )

                if not isinstance(old, int):
                    old = 50

                if level != old or not previous:
                    changes.append((f"{prefix}{name}", old, level))

        format_defaults_dict(ev.source["content"], previous)

        # Minimum level to send event changes

        for ev_type, level in levels.events.items():
            old = events_previous.get(
                ev_type,

                levels.defaults.state_default
                if ev_type.startswith("m.room.") else
                levels.defaults.events_default,
            )

            if level != old or not previous:
                event_changes.append((ev_type, old, level))

        # User level changes

        for user_id, level in levels.users.items():
            old = users_previous.get(user_id, levels.defaults.users_default)

            if level != old or not previous:
                user_changes.append((user_id, old, level))

        # Gather and format changes

        if changes or event_changes or user_changes:
            changes.sort(key=lambda c: (c[2], c[0]))
            event_changes.sort(key=lambda c: (c[2], c[0]))
            user_changes.sort(key=lambda c: (c[2], c[0]))

            all_changes = changes + event_changes + user_changes

            if len(all_changes) == 1:
                co = HTML_PROCESSOR.from_markdown(
                    "%%1 changed the level for **%s**: %s → %s " % (
                        all_changes[0][0],
                        lvl(all_changes[0][1]).lower(),
                        lvl(all_changes[0][2]).lower(),
                    ),
                    inline = True,
                )
            else:
                co = HTML_PROCESSOR.from_markdown("\n".join([
                    "%1 changed the room's permissions",
                    "",
                    "Change | Previous | Current ",
                    "--- | --- | ---",
                    *[
                        f"{name} | {lvl(old)} | {lvl(now)}"
                        for name, old, now in all_changes
                    ],
                ]))
        else:
            co = "%1 didn't change the room's permissions"

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

            reason = escape(
                f", reason: {now['reason']}" if now.get("reason") else "",
            )

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
                escape(prev.get("displayname") or ev.state_key),
                escape(now.get("displayname") or ev.state_key),
            ))

        if changed:
            # Update our account profile if the event is newer than last update
            if ev.state_key == self.user_id:
                account = self.models["accounts"][self.user_id]

                if account.profile_updated < ev_date:
                    account.set_fields(
                        profile_updated = ev_date,
                        display_name    = now.get("displayname") or "",
                        avatar_url      = now.get("avatar_url") or "",
                    )

            if self.client.backend.ui_settings["hideProfileChangeEvents"]:
                return None

            return (
                TypeSpecifier.ProfileChange,
                "%1 changed their {}".format(" and ".join(changed)),
            )

        # log.warning("Unknown member ev.: %s", json.dumps(vars(ev), indent=4))
        return None


    async def onRoomMemberEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomMemberEvent,
    ) -> None:
        # The event can be a past event, don't trust it to update the model
        # room's current state.
        if ev.state_key in room.users:
            await self.client.add_member(room, user_id=ev.state_key)
        else:
            await self.client.remove_member(room, user_id=ev.state_key)

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


    async def onRoomAliasEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomAliasEvent,
    ) -> None:
        if ev.canonical_alias:
            url  = f"https://matrix.to/#/{quote(ev.canonical_alias)}"
            link = f"<a href='{url}'>{escape(ev.canonical_alias)}</a>"
            co   = f"%1 set the room's main address to {link}"
        else:
            co = "%1 removed the room's main address"

        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomNameEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomNameEvent,
    ) -> None:
        if ev.name:
            co = f"%1 changed the room's name to \"{escape(ev.name)}\""
        else:
            co = "%1 removed the room's name"

        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomAvatarEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomAvatarEvent,
    ) -> None:
        if ev.avatar_url:
            co = "%1 changed the room's picture"
        else:
            co = "%1 removed the room's picture"

        http = await self.client.mxc_to_http(ev.avatar_url)

        await self.client.register_nio_event(
            room, ev, content=co, media_url=ev.avatar_url, media_http_url=http,
        )


    async def onRoomTopicEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomTopicEvent,
    ) -> None:
        if ev.topic:
            topic = HTML_PROCESSOR.filter(plain2html(ev.topic), inline=True)
            co    = f"%1 changed the room's topic to \"{topic}\""
        else:
            co = "%1 removed the room's topic"

        await self.client.register_nio_event(room, ev, content=co)


    async def onRoomEncryptionEvent(
        self, room: nio.MatrixRoom, ev: nio.RoomEncryptionEvent,
    ) -> None:
        co = "%1 turned on encryption for this room"
        await self.client.register_nio_event(room, ev, content=co)


    async def onMegolmEvent(
        self, room: nio.MatrixRoom, ev: nio.MegolmEvent,
    ) -> None:
        co = "%1 sent an undecryptable message"
        await self.client.register_nio_event(room, ev, content=co)


    async def onBadEvent(
        self, room: nio.MatrixRoom, ev: nio.BadEvent,
    ) -> None:
        co = f"%1 sent a malformed <b>{escape(ev.type)}</b> event"
        await self.client.register_nio_event(room, ev, content=co)


    async def onUnknownBadEvent(
        self, room: nio.MatrixRoom, ev: nio.UnknownBadEvent,
    ) -> None:
        co = "%1 sent a malformed event lacking a minimal structure"
        await self.client.register_nio_event(room, ev, content=co)


    async def onUnknownEvent(
        self, room: nio.MatrixRoom, ev: nio.UnknownEvent,
    ) -> None:
        if self.client.backend.ui_settings["hideUnknownEvents"]:
            await self.client.register_nio_room(room)
            return

        co = f"%1 sent an unsupported <b>{escape(ev.type)}</b> event"
        await self.client.register_nio_event(room, ev, content=co)


    async def onUnknownEncryptedEvent(
        self, room: nio.MatrixRoom, ev: nio.UnknownEncryptedEvent,
    ) -> None:
        co = (
            f"%1 sent an <b>{escape(ev.type)}</b> event encrypted with "
            f"unsupported <b>{escape(ev.algorithm)}</b> algorithm"
        )
        await self.client.register_nio_event(room, ev, content=co)


    async def onInviteEvent(
        self, room: nio.MatrixRoom, ev: nio.InviteEvent,
    ) -> None:
        await self.client.register_nio_room(room)


    # Ephemeral event callbacks

    async def onTypingNoticeEvent(
        self, room: nio.MatrixRoom, ev: nio.TypingNoticeEvent,
    ) -> None:
        # Prevent recent past typing notices from being shown for a split
        # second on client startup:
        if not self.client.first_sync_done.is_set():
            return

        await self.client.register_nio_room(room)

        room_id = room.room_id

        room_item = self.models[self.user_id, "rooms"][room_id]

        room_item.typing_members = sorted(
            room.user_name(user_id) or user_id for user_id in ev.users
            if user_id not in self.client.backend.clients
        )


    async def onReceiptEvent(
        self, room: nio.MatrixRoom, ev: nio.ReceiptEvent,
    ) -> None:
        model = self.models[self.user_id, room.room_id, "members"]

        for receipt in ev.receipts:
            if receipt.receipt_type != "m.read":
                continue

            member = model.get(receipt.user_id)

            if member:
                timestamp = receipt.timestamp / 1000
                member.set_fields(
                    last_read_event = receipt.event_id,
                    last_read_at    = datetime.fromtimestamp(timestamp),
                )


    # Presence event callbacks

    async def onPresenceEvent(self, ev: nio.PresenceEvent) -> None:
        presence = self.client.backend.presences.get(ev.user_id, Presence())

        presence.currently_active = ev.currently_active or False
        presence.status_msg       = ev.status_msg or ""
        presence.last_active_at   = (
            datetime.now() - timedelta(milliseconds=ev.last_active_ago)
        ) if ev.last_active_ago else datetime.fromtimestamp(0)

        presence.presence = Presence.State(ev.presence) if ev.presence\
                                    else Presence.State.offline

        # Add all existing members related to this presence
        for room_id in self.models[self.user_id, "rooms"]:
            member = self.models[self.user_id, room_id, "members"].get(
                ev.user_id,
            )

            if member:
                presence.members[room_id] = member

        # Update members and accounts
        presence.update_members()

        # Check if presence event is ours
        if (
            ev.user_id in self.models["accounts"] and
            self.models["accounts"][ev.user_id].presence !=
            Presence.State.offline and
            not (
                presence.presence == Presence.State.offline and
                self.models["accounts"][ev.user_id].presence !=
                Presence.State.echo_invisible
            )
        ):
            account = self.models["accounts"][ev.user_id]

            # Set status_msg if none is set on the server and we have one
            if (
                not presence.status_msg                           and
                account.status_msg                                and
                ev.user_id in self.client.backend.clients         and
                account.presence != Presence.State.echo_invisible and
                presence.presence == Presence.State.offline
            ):
                asyncio.ensure_future(
                    self.client.backend.clients[ev.user_id].set_presence(
                        presence.presence.value,
                        account.status_msg,
                    ),
                )

            # Do not fight back presence from other clients
            self.client.backend.clients[ev.user_id]._presence = ev.presence

            # Servers that send presence events support presence
            account.presence_support = True

            # Save the presence for the next resume
            if account.save_presence:
                status_msg = presence.status_msg
                state      = presence.presence

                if account.presence == Presence.State.echo_invisible:
                    status_msg = account.status_msg
                    state      = Presence.State.invisible

                await self.client.backend.saved_accounts.update(
                    user_id    = ev.user_id,
                    status_msg = status_msg,
                    presence   = state.value,
                )

            presence.update_account()

        self.client.backend.presences[ev.user_id] = presence
