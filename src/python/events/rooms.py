from datetime import datetime
from enum import auto
from typing import List, Sequence, Type, Union

from dataclasses import dataclass, field

import nio
from nio.rooms import MatrixRoom

from .event import AutoStrEnum, Event


@dataclass
class RoomUpdated(Event):
    user_id:        str           = field()
    category:       str           = field()
    room_id:        str           = field()
    display_name:   str           = ""
    avatar_url:     str           = ""
    topic:          str           = ""
    typing_members: Sequence[str] = ()
    inviter_id:     str           = ""


    @classmethod
    def from_nio(cls,
                 user_id:  str,
                 category: str,
                 room:     MatrixRoom,
                 info:     nio.RoomInfo) -> "RoomUpdated":

        typing: List[str] = []

        if hasattr(info, "ephemeral"):
            for ev in info.ephemeral:
                if isinstance(ev, nio.TypingNoticeEvent):
                    typing = ev.users

        name = room.name or room.canonical_alias

        if not name:
            name = room.group_name()
            name = "" if name == "Empty room?" else name

        return cls(
            user_id        = user_id,
            category       = category,
            room_id        = room.room_id,
            display_name   = name,
            avatar_url     = room.gen_avatar_url or "",
            topic          = room.topic or "",
            inviter_id     = getattr(room, "inviter", "") or "",
            typing_members = typing,
        )


@dataclass
class RoomDeleted(Event):
    user_id:  str = field()
    category: str = field()
    room_id:  str = field()


@dataclass
class RoomMemberUpdated(Event):
    room_id: str  = field()
    user_id: str  = field()
    typing:  bool = field()


@dataclass
class RoomMemberDeleted(Event):
    room_id: str  = field()
    user_id: str  = field()


# Timeline

class ContentType(AutoStrEnum):
    html     = auto()
    image    = auto()
    audio    = auto()
    video    = auto()
    file     = auto()
    location = auto()


@dataclass
class TimelineEventReceived(Event):
    event_type:    Type[nio.Event] = field()
    room_id:       str             = field()
    event_id:      str             = field()
    sender_id:     str             = field()
    date:          datetime        = field()
    content:       str             = field()
    content_type:  ContentType     = ContentType.html
    is_local_echo: bool            = False

    show_name_line: bool                       = False
    translatable:   Union[bool, Sequence[str]] = True

    target_user_id: str = ""

    @classmethod
    def from_nio(cls, room: MatrixRoom, ev: nio.Event, **fields
                ) -> "TimelineEventReceived":
        return cls(
            event_type = type(ev),
            room_id    = room.room_id,
            event_id   = ev.event_id,
            sender_id  = ev.sender,
            date       = datetime.fromtimestamp(ev.server_timestamp / 1000),
            target_user_id = getattr(ev, "state_key", "") or "",
            **fields
        )


@dataclass
class TimelineMessageReceived(TimelineEventReceived):
    show_name_line: bool                       = True
    translatable:   Union[bool, Sequence[str]] = False
