from datetime import datetime
from enum import auto
from typing import Dict, Optional, Sequence, Type, Union

from dataclasses import dataclass, field

import nio

from .event import AutoStrEnum, Event


@dataclass
class RoomUpdated(Event):
    user_id:         str                = field()
    category:        str                = field()
    room_id:         str                = field()
    display_name:    Optional[str]      = None
    avatar_url:      Optional[str]      = None
    topic:           Optional[str]      = None
    last_event_date: Optional[datetime] = None

    inviter:    Optional[str]            = None
    left_event: Optional[Dict[str, str]] = None


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

    target_user_id: Optional[str] = None

    @classmethod
    def from_nio(cls, room, ev, **fields) -> "TimelineEventReceived":
        return cls(
            event_type = type(ev),
            room_id    = room.room_id,
            event_id   = ev.event_id,
            sender_id  = ev.sender,
            date       = datetime.fromtimestamp(ev.server_timestamp / 1000),
            target_user_id = getattr(ev, "state_key", None),
            **fields
        )


@dataclass
class TimelineMessageReceived(TimelineEventReceived):
    show_name_line: bool                       = True
    translatable:   Union[bool, Sequence[str]] = False
