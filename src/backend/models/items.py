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

OptionalExceptionType = Union[Type[None], Type[Exception]]

ZERO_DATE = datetime.fromtimestamp(0)

PRESENCE_ORDER: Dict[str, int] = {
    "online":      0,
    "unavailable": 1,
    "offline":     2,
}


class TypeSpecifier(AutoStrEnum):
    """Enum providing clarification of purpose for some matrix events."""

    Unset            = auto()
    ProfileChange    = auto()
    MembershipChange = auto()


@dataclass
class Presence:
    """Represents a single matrix user's presence fields.

    These objects are stored in `Backend.presences`, indexed by user ID.
    It must only be instanced when receiving a `PresenceEvent` or
    registering an `Account` model item.

    When receiving a `PresenceEvent`, we get or create a `Presence` object in
    `Backend.presences` for the targeted user. If the user is registered in any
    room, add its `Member` model item to `members`. Finally, update every
    `Member` presence fields inside `members`.

    When a room member is registered, we try to find a `Presence` in
    `Backend.presences` for that user ID. If found, the `Member` item is added
    to `members`.

    When an Account model is registered, we create a `Presence` in
    `Backend.presences` for the accountu's user ID whether the server supports
    presence or not (we cannot know yet at this point),
    and assign that `Account` to the `Presence.account` field.

    Special attributes:
        members: A `{room_id: Member}` dict for storing room members related to
            this `Presence`. As each room has its own `Member`s objects, we
            have to keep track of their presence fields. `Member`s are indexed
            by room ID.

        account: `Account` related to this `Presence`, if any. Should be
            assigned when client starts (`MatrixClient._start()`) and
            cleared when client stops (`MatrixClient._start()`).
    """

    class State(AutoStrEnum):
        offline     = auto()  # can mean offline, invisible or unknwon
        unavailable = auto()
        online      = auto()
        invisible   = auto()

        echo_unavailable = auto()
        echo_online      = auto()
        echo_invisible   = auto()

        def __lt__(self, other: "Presence.State") -> bool:
            return PRESENCE_ORDER[self.value] < PRESENCE_ORDER[other.value]


    presence:         State    = State.offline
    currently_active: bool     = False
    last_active_at:   datetime = ZERO_DATE
    status_msg:       str      = ""

    members: Dict[str, "Member"] = field(default_factory=dict)
    account: Optional["Account"] = None

    def update_members(self) -> None:
        """Update presence fields of every `M̀ember` in `members`.

        Currently it is only called when receiving a `PresenceEvent` and when
        registering room members.
        """

        for member in self.members.values():
            member.set_fields(
                presence         = self.presence,
                status_msg       = self.status_msg,
                last_active_at   = self.last_active_at,
                currently_active = self.currently_active,
            )

    def update_account(self) -> None:
        """Update presence fields of `Account` related to this `Presence`."""

        # Do not update if account is changing to invisible.
        # When setting presence to invisible, the server will give us a
        # presence event telling us we are offline, but we do not want to set
        # account presence to offline.
        if (
            not self.account or
            self.presence         == self.State.offline and
            self.account.presence != self.State.echo_invisible
        ):
            return

        fields: Dict[str, Any] = {}

        if self.account.presence == self.State.echo_invisible:
            fields["presence"] = self.State.invisible
        else:
            fields["presence"]   = self.presence
            fields["status_msg"] = self.status_msg

        fields["last_active_at"]   = self.last_active_at
        fields["currently_active"] = self.currently_active

        self.account.set_fields(**fields)


@dataclass
class Account(ModelItem):
    """A logged in matrix account."""

    id:               str      = field()
    order:            int      = -1
    display_name:     str      = ""
    avatar_url:       str      = ""
    max_upload_size:  int      = 0
    profile_updated:  datetime = ZERO_DATE
    connecting:       bool     = False
    total_unread:     int      = 0
    total_highlights: int      = 0
    local_unreads:    bool     = False
    local_highlights: bool     = False

    # For some reason, Account cannot inherit Presence, because QML keeps
    # complaining type error on unknown file
    presence_support: bool           = False
    save_presence:    bool           = True
    presence:         Presence.State = Presence.State.offline
    currently_active: bool           = False
    last_active_at:   datetime       = ZERO_DATE
    status_msg:       str            = ""

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

    default_power_level:  int  = 0
    own_power_level:      int  = 0
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
    can_set_power_levels: bool = False

    last_event_date: datetime = ZERO_DATE

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
    profile_updated: datetime = ZERO_DATE

    last_read_event: str      = ""
    last_read_at:    datetime = ZERO_DATE

    presence:         Presence.State = Presence.State.offline
    currently_active: bool           = False
    last_active_at:   datetime       = ZERO_DATE
    status_msg:       str            = ""

    def __lt__(self, other: "Member") -> bool:
        """Sort by presence, power level, then by display name/user ID."""

        name       = self.display_name or self.id[1:]
        other_name = other.display_name or other.id[1:]

        return (
            self.invited,
            other.power_level,
            self.presence,
            name.lower(),
        ) < (
            other.invited,
            self.power_level,
            other.presence,
            other_name.lower(),
        )


class UploadStatus(AutoStrEnum):
    """Enum describing the status of an upload operation."""

    Preparing = auto()
    Uploading = auto()
    Caching   = auto()
    Error     = auto()


@dataclass
class Upload(ModelItem):
    """Represent a running or failed file upload operation."""

    id:       UUID = field()
    filepath: Path = Path("-")

    total_size: int       = 0
    uploaded:   int       = 0
    speed:      float     = 0
    time_left:  timedelta = timedelta(0)
    paused:     bool      = False

    status:     UploadStatus          = UploadStatus.Preparing
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
