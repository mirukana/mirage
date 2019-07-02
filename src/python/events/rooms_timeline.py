from datetime import datetime
from enum import auto

from dataclasses import dataclass, field

from .event import AutoStrEnum, Event


class EventType(AutoStrEnum):
    text     = auto()
    html     = auto()
    file     = auto()
    image    = auto()
    audio    = auto()
    video    = auto()
    location = auto()
    notice   = auto()


@dataclass
class TimelineEvent(Event):
    type:          EventType = field()
    room_id:       str       = field()
    event_id:      str       = field()
    sender_id:     str       = field()
    date:          datetime  = field()
    is_local_echo: bool      = field()


@dataclass
class HtmlMessageReceived(TimelineEvent):
    content: str = field()
