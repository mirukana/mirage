# SPDX-License-Identifier: LGPL-3.0-or-later

"""`ModelItem` subclasses definitions."""

import json
from dataclasses import asdict, dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Type, Union
from uuid import UUID

import lxml  # nosec

import nio

from ..utils import AutoStrEnum, auto
from .model_item import ModelItem

ZeroDate              = datetime.fromtimestamp(0)
OptionalExceptionType = Union[Type[None], Type[Exception]]



class TypeSpecifier(AutoStrEnum):
    """Enum providing clarification of purpose for some matrix events."""

    Unset            = auto()
    ProfileChange    = auto()
    MembershipChange = auto()


class Presence(AutoStrEnum):
    Offline     = auto()  # can mean offline, invisible or unknwon
    Unavailable = auto()
    Online      = auto()


@dataclass
class Account(ModelItem):
    """A logged in matrix account."""

    id:               str      = field()
    order:            int      = -1
    display_name:     str      = ""
    avatar_url:       str      = ""
    max_upload_size:  int      = 0
    profile_updated:  datetime = ZeroDate
    first_sync_done:  bool     = False
    total_unread:     int      = 0
    total_highlights: int      = 0
    local_unreads:    bool     = False
    local_highlights: bool     = False

    def __lt__(self, other: "Account") -> bool:
        """Sort by order, then by user ID."""
        return (self.order, self.id.lower()) < (other.order, other.id.lower())


@dataclass
class Room(ModelItem):
    """A matrix room we are invited to, are or were member of."""

    id:             str  = field()
    for_account:    str  = ""
    given_name:     str  = ""
    display_name:   str  = ""
    main_alias:     str  = ""
    avatar_url:     str  = ""
    plain_topic:    str  = ""
    topic:          str  = ""
    inviter_id:     str  = ""
    inviter_name:   str  = ""
    inviter_avatar: str  = ""
    left:           bool = False

    typing_members: List[str] = field(default_factory=list)

    federated:          bool = True
    encrypted:          bool = False
    unverified_devices: bool = False
    invite_required:    bool = True
    guests_allowed:     bool = True

    can_invite:           bool = False
    can_kick:             bool = False
    can_redact_all:       bool = False
    can_send_messages:    bool = False
    can_set_name:         bool = False
    can_set_topic:        bool = False
    can_set_avatar:       bool = False
    can_set_encryption:   bool = False
    can_set_join_rules:   bool = False
    can_set_guest_access: bool = False

    last_event_date: datetime = ZeroDate

    unreads:          int  = 0
    highlights:       int  = 0
    local_unreads:    bool = False
    local_highlights: bool = False

    def __lt__(self, other: "Room") -> bool:
        """Sort by membership, highlights/unread events, last event date, name.

        Invited rooms are first, then joined rooms, then left rooms.
        Within these categories, sort by unread highlighted messages, then
        unread messages, then by whether the room hasn't been read locally,
        then last event date (room with recent messages are first),
        then by display names or ID.
        """

        # Left rooms may still have an inviter_id, so check left first.
        return (
            self.for_account,
            self.left,
            other.inviter_id,
            bool(other.highlights),
            bool(other.local_highlights),
            bool(other.unreads),
            bool(other.local_unreads),
            other.last_event_date,
            (self.display_name or self.id).lower(),

        ) < (
            other.for_account,
            other.left,
            self.inviter_id,
            bool(self.highlights),
            bool(self.local_highlights),
            bool(self.unreads),
            bool(self.local_unreads),
            self.last_event_date,
            (other.display_name or other.id).lower(),
        )


@dataclass
class AccountOrRoom(Account, Room):
    type:          Union[Type[Account], Type[Room]] = Account
    account_order: int                              = -1

    def __lt__(self, other: "AccountOrRoom") -> bool:  # type: ignore
        return (
            self.account_order,
            self.id if self.type is Account else self.for_account,
            other.type is Account,
            self.left,
            other.inviter_id,
            bool(other.highlights),
            bool(other.local_highlights),
            bool(other.unreads),
            bool(other.local_unreads),
            other.last_event_date,
            (self.display_name or self.id).lower(),

        ) < (
            other.account_order,
            other.id if other.type is Account else other.for_account,
            self.type is Account,
            other.left,
            self.inviter_id,
            bool(self.highlights),
            bool(self.local_highlights),
            bool(self.unreads),
            bool(self.local_unreads),
            self.last_event_date,
            (other.display_name or other.id).lower(),
        )


@dataclass
class Member(ModelItem):
    """A member in a matrix room."""

    id:              str      = field()
    display_name:    str      = ""
    avatar_url:      str      = ""
    typing:          bool     = False
    power_level:     int      = 0
    invited:         bool     = False
    profile_updated: datetime = ZeroDate

    last_read_event: str      = ""
    last_read_at:    datetime = ZeroDate

    last_active_ago:  int      = -1
    currently_active: bool     = False
    presence:         Presence = Presence.Offline
    status_message:   str      = ""


    def __lt__(self, other: "Member") -> bool:
        """Sort by power level, then by display name/user ID."""

        name       = self.display_name or self.id[1:]
        other_name = other.display_name or other.id[1:]

        return (
            self.invited, other.power_level, name.lower(),
        ) < (
            other.invited, self.power_level, other_name.lower(),
        )


class UploadStatus(AutoStrEnum):
    """Enum describing the status of an upload operation."""

    Uploading = auto()
    Caching   = auto()
    Error     = auto()


@dataclass
class Upload(ModelItem):
    """Represent a running or failed file upload operation."""

    id:       UUID = field()
    filepath: Path = field()

    total_size: int       = 0
    uploaded:   int       = 0
    speed:      float     = 0
    time_left:  timedelta = timedelta(0)
    paused:     bool      = False

    status:     UploadStatus          = UploadStatus.Uploading
    error:      OptionalExceptionType = type(None)
    error_args: Tuple[Any, ...]       = ()

    start_date: datetime = field(init=False, default_factory=datetime.now)


    def __lt__(self, other: "Upload") -> bool:
        """Sort by the start date, from newest upload to oldest."""

        return self.start_date > other.start_date


@dataclass
class Event(ModelItem):
    """A matrix state event or message."""

    id:            str                 = field()
    event_id:      str                 = field()
    event_type:    Type[nio.Event]     = field()
    date:          datetime            = field()
    sender_id:     str                 = field()
    sender_name:   str                 = field()
    sender_avatar: str                 = field()
    fetch_profile: bool                = False

    content:        str                   = ""
    inline_content: str                   = ""
    reason:         str                   = ""
    links:          List[str]             = field(default_factory=list)
    mentions:       List[Tuple[str, str]] = field(default_factory=list)

    type_specifier: TypeSpecifier = TypeSpecifier.Unset

    target_id:     str = ""
    target_name:   str = ""
    target_avatar: str = ""
    redacter_id:   str = ""
    redacter_name: str = ""

    is_local_echo: bool                = False
    source:        Optional[nio.Event] = None

    media_url:        str            = ""
    media_title:      str            = ""
    media_width:      int            = 0
    media_height:     int            = 0
    media_duration:   int            = 0
    media_size:       int            = 0
    media_mime:       str            = ""
    media_crypt_dict: Dict[str, Any] = field(default_factory=dict)

    thumbnail_url:        str            = ""
    thumbnail_mime:       str            = ""
    thumbnail_width:      int            = 0
    thumbnail_height:     int            = 0
    thumbnail_crypt_dict: Dict[str, Any] = field(default_factory=dict)

    def __lt__(self, other: "Event") -> bool:
        """Sort by date in descending order, from newest to oldest."""

        return self.date > other.date

    @staticmethod
    def parse_links(text: str) -> List[str]:
        """Return list of URLs (`<a href=...>` tags) present in the text."""

        if not text.strip():
            return []

        return [link[2] for link in lxml.html.iterlinks(text)]

    def serialize_field(self, field: str) -> Any:
        if field == "source":
            source_dict = asdict(self.source) if self.source else {}
            return json.dumps(source_dict)

        return super().serialize_field(field)


@dataclass
class Device(ModelItem):
    """A matrix user's device. This class is currently unused."""

    id:             str  = field()
    ed25519_key:    str  = field()
    trusted:        bool = False
    blacklisted:    bool = False
    display_name:   str  = ""
    last_seen_ip:   str  = ""
    last_seen_date: str  = ""
