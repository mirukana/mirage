from datetime import datetime
from typing import Dict, Optional

from dataclasses import dataclass, field

from .event import Event


@dataclass
class RoomUpdated(Event):
    room_id:         str                = field()
    display_name:    Optional[str]      = None
    avatar_url:      Optional[str]      = None
    topic:           Optional[str]      = None
    last_event_date: Optional[datetime] = None

    inviter:    Optional[Dict[str, str]] = None
    left_event: Optional[Dict[str, str]] = None


@dataclass
class RoomDeleted(Event):
    room_id: str = field()


@dataclass
class RoomMemberUpdated(Event):
    room_id: str  = field()
    user_id: str  = field()
    typing:  bool = field()


@dataclass
class RoomMemberDeleted(Event):
    room_id: str  = field()
    user_id: str  = field()
