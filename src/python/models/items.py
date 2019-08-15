from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional

from ..html_filter import HTML_FILTER
from .model_item import ModelItem


@dataclass
class Account(ModelItem):
    main_key = "user_id"

    user_id:         str      = field()
    display_name:    str      = ""
    avatar_url:      str      = ""
    profile_updated: datetime = field(default_factory=datetime.now)

    def __lt__(self, other: "Account") -> bool:
        name       = self.display_name or self.user_id[1:]
        other_name = other.display_name or other.user_id[1:]
        return name < other_name


@dataclass
class Room(ModelItem):
    main_key = "room_id"

    room_id:        str       = field()
    display_name:   str       = ""
    avatar_url:     str       = ""
    topic:          str       = ""
    inviter_id:     str       = ""
    inviter_name:   str       = ""
    inviter_avatar: str       = ""
    left:           bool      = False
    filter_string:  str       = ""
    typing_members: List[str] = field(default_factory=list)

    # Event __dict__
    last_event: Optional[Dict[str, Any]] = field(default=None, repr=False)

    def __lt__(self, other: "Room") -> bool:
        # Left rooms may still have an inviter_id, check left first.
        if self.left and not other.left:
            return True

        if other.inviter_id and not self.inviter_id:
            return True

        name       = self.display_name or self.room_id
        other_name = other.display_name or other.room_id
        return name < other_name


@dataclass
class Member(ModelItem):
    main_key = "user_id"

    user_id:       str  = field()
    display_name:  str  = ""
    avatar_url:    str  = ""
    typing:        bool = False
    power_level:   int  = 0
    filter_string: str  = ""

    def __lt__(self, other: "Member") -> bool:
        name       = self.display_name or self.user_id[1:]
        other_name = other.display_name or other.user_id[1:]
        return name < other_name


@dataclass
class Event(ModelItem):
    main_key = "event_id"

    client_id:      str      = field()
    event_id:       str      = field()
    event_type:     str      = field()  # Type[nio.Event]
    content:        str      = field()
    inline_content: str      = field()
    date:           datetime = field()

    sender_id:     str = field()
    sender_name:   str = field()
    sender_avatar: str = field()

    target_id:     str = ""
    target_name:   str = ""
    target_avatar: str = ""

    is_local_echo: bool = False

    def __post_init__(self) -> None:
        self.inline_content = HTML_FILTER.filter_inline(self.content)


    def __lt__(self, other: "Event") -> bool:
        # Sort events from newest to oldest. return True means return False.
        # Local echoes always stay first.
        if self.is_local_echo and not other.is_local_echo:
            return True

        if other.is_local_echo and not self.is_local_echo:
            return False

        return self.date > other.date


@dataclass
class Device(ModelItem):
    main_key = "device_id"

    device_id:      str  = field()
    ed25519_key:    str  = field()
    trusted:        bool = False
    blacklisted:    bool = False
    display_name:   str  = ""
    last_seen_ip:   str  = ""
    last_seen_date: str  = ""
