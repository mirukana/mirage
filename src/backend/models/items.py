# Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
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

from ..presence import Presence
from ..utils import AutoStrEnum, auto, strip_html_tags
from .model_item import ModelItem

OptionalExceptionType = Union[Type[None], Type[Exception]]

ZERO_DATE = datetime.fromtimestamp(0)


class TypeSpecifier(AutoStrEnum):
    """Enum providing clarification of purpose for some matrix events."""

    Unset            = auto()
    ProfileChange    = auto()
    MembershipChange = auto()


class PingStatus(AutoStrEnum):
    """Enum for the status of a homeserver ping operation."""

    Done    = auto()
    Pinging = auto()
    Failed  = auto()


class RoomNotificationOverride(AutoStrEnum):
    """Possible per-room notification override settings, as displayed in the
    left sidepane's context menu when right-clicking a room.
    """
    UseDefaultSettings = auto()
    AllEvents          = auto()
    HighlightsOnly     = auto()
    IgnoreEvents       = auto()


@dataclass(eq=False)
class Homeserver(ModelItem):
    """A homeserver we can connect to. The `id` field is the server's URL."""

    id:             str         = field()
    name:           str         = field()
    site_url:       str         = field()
    country:        str         = field()
    ping:           int         = -1
    status:         PingStatus  = PingStatus.Pinging
    stability:      float       = -1
    downtimes_ms:   List[float] = field(default_factory=list)

    def __lt__(self, other: "Homeserver") -> bool:
        return (self.name.lower(), self.id) < (other.name.lower(), other.id)


@dataclass(eq=False)
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

    # For some reason, Account cannot inherit Presence, because QML keeps
    # complaining type error on unknown file
    presence_support: bool           = False
    save_presence:    bool           = True
    presence:         Presence.State = Presence.State.offline
    currently_active: bool           = False
    last_active_at:   datetime       = ZERO_DATE
    status_msg:       str            = ""

    def __lt__(self, other: "Account") -> bool:
        return (self.order, self.id) < (other.order, other.id)


@dataclass(eq=False)
class PushRule(ModelItem):
    """A push rule configured for one of our account."""

    id:           Tuple[str, str]      = field()  # (kind.value, rule_id)
    kind:         nio.PushRuleKind     = field()
    rule_id:      str                  = field()
    order:        int                  = field()
    default:      bool                 = field()
    enabled:      bool                 = True
    conditions:   List[Dict[str, Any]] = field(default_factory=list)
    pattern:      str                  = ""
    actions:      List[Dict[str, Any]] = field(default_factory=list)
    notify:       bool                 = False
    highlight:    bool                 = False
    bubble:       bool                 = False
    sound:        str                  = ""  # usually "default" when set
    urgency_hint: bool                 = False

    def __lt__(self, other: "PushRule") -> bool:
        return (
            self.kind is nio.PushRuleKind.underride,
            self.kind is nio.PushRuleKind.sender,
            self.kind is nio.PushRuleKind.room,
            self.kind is nio.PushRuleKind.content,
            self.kind is nio.PushRuleKind.override,
            self.order,
            self.id,
        ) < (
            other.kind is nio.PushRuleKind.underride,
            other.kind is nio.PushRuleKind.sender,
            other.kind is nio.PushRuleKind.room,
            other.kind is nio.PushRuleKind.content,
            other.kind is nio.PushRuleKind.override,
            other.order,
            other.id,
        )


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

    unreads:       int  = 0
    highlights:    int  = 0
    local_unreads: bool = False

    notification_setting: RoomNotificationOverride = \
        RoomNotificationOverride.UseDefaultSettings

    lexical_sorting: bool = False
    pinned:          bool = False

    def __lt__(self, other: "Room") -> bool:
        by_activity = not self.lexical_sorting

        return (
            self.for_account,
            other.pinned,
            self.left,  # Left rooms may have an inviter_id, check them first
            bool(other.inviter_id),
            bool(by_activity and other.highlights),
            bool(by_activity and other.unreads),
            bool(by_activity and other.local_unreads),
            other.last_event_date if by_activity else ZERO_DATE,
            (self.display_name or self.id).lower(),
            self.id,

        ) < (
            other.for_account,
            self.pinned,
            other.left,
            bool(self.inviter_id),
            bool(by_activity and self.highlights),
            bool(by_activity and self.unreads),
            bool(by_activity and self.local_unreads),
            self.last_event_date if by_activity else ZERO_DATE,
            (other.display_name or other.id).lower(),
            other.id,
        )


@dataclass(eq=False)
class AccountOrRoom(Account, Room):
    """The left sidepane in the GUI lists a mixture of accounts and rooms
    giving a tree view illusion. Since all items in a QML ListView must have
    the same available properties, this class inherits both
    `Account` and `Room` to fulfill that purpose.
    """

    type:          Union[Type[Account], Type[Room]] = Account
    account_order: int                              = -1

    def __lt__(self, other: "AccountOrRoom") -> bool:  # type: ignore
        by_activity = not self.lexical_sorting

        return (
            self.account_order,
            self.id if self.type is Account else self.for_account,
            other.type is Account,
            other.pinned,
            self.left,
            bool(other.inviter_id),
            bool(by_activity and other.highlights),
            bool(by_activity and other.unreads),
            bool(by_activity and other.local_unreads),
            other.last_event_date if by_activity else ZERO_DATE,
            (self.display_name or self.id).lower(),
            self.id,

        ) < (
            other.account_order,
            other.id if other.type is Account else other.for_account,
            self.type is Account,
            self.pinned,
            other.left,
            bool(self.inviter_id),
            bool(by_activity and self.highlights),
            bool(by_activity and self.unreads),
            bool(by_activity and self.local_unreads),
            self.last_event_date if by_activity else ZERO_DATE,
            (other.display_name or other.id).lower(),
            other.id,
        )


@dataclass(eq=False)
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

    presence:         Presence.State = Presence.State.offline
    currently_active: bool           = False
    last_active_at:   datetime       = ZERO_DATE
    status_msg:       str            = ""

    def __lt__(self, other: "Member") -> bool:
        return (
            self.invited,
            other.power_level,
            self.presence,
            (self.display_name or self.id[1:]).lower(),
            self.id,
        ) < (
            other.invited,
            self.power_level,
            other.presence,
            (other.display_name or other.id[1:]).lower(),
            other.id,
        )


class TransferStatus(AutoStrEnum):
    """Enum describing the status of an upload operation."""

    Preparing   = auto()
    Transfering = auto()
    Caching     = auto()
    Error       = auto()


@dataclass(eq=False)
class Transfer(ModelItem):
    """Represent a running or failed file upload/download operation."""

    id:        UUID = field()
    is_upload: bool = field()
    filepath:  Path = Path("-")

    total_size:  int       = 0
    transferred: int       = 0
    speed:       float     = 0
    time_left:   timedelta = timedelta(0)
    paused:      bool      = False

    status:     TransferStatus        = TransferStatus.Preparing
    error:      OptionalExceptionType = type(None)
    error_args: Tuple[Any, ...]       = ()

    start_date: datetime = field(init=False, default_factory=datetime.now)


    def __lt__(self, other: "Transfer") -> bool:
        return (self.start_date, self.id) > (other.start_date, other.id)


@dataclass(eq=False)
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

    content:           str                   = ""
    inline_content:    str                   = ""
    reason:            str                   = ""
    links:             List[str]             = field(default_factory=list)
    mentions:          List[Tuple[str, str]] = field(default_factory=list)

    type_specifier: TypeSpecifier = TypeSpecifier.Unset

    target_id:     str = ""
    target_name:   str = ""
    target_avatar: str = ""
    redacter_id:   str = ""
    redacter_name: str = ""

    # {user_id: server_timestamp} - QML can't parse dates from JSONified dicts
    last_read_by:  Dict[str, int] = field(default_factory=dict)
    read_by_count: int            = 0

    is_local_echo: bool                = False
    source:        Optional[nio.Event] = None

    media_url:        str              = ""
    media_http_url:   str              = ""
    media_title:      str              = ""
    media_width:      int              = 0
    media_height:     int              = 0
    media_duration:   int              = 0
    media_size:       int              = 0
    media_mime:       str              = ""
    media_crypt_dict: Dict[str, Any]   = field(default_factory=dict)
    media_local_path: Union[str, Path] = ""

    thumbnail_url:        str            = ""
    thumbnail_mime:       str            = ""
    thumbnail_width:      int            = 0
    thumbnail_height:     int            = 0
    thumbnail_crypt_dict: Dict[str, Any] = field(default_factory=dict)

    def __lt__(self, other: "Event") -> bool:
        return (self.date, self.id) > (other.date, other.id)

    @property
    def plain_content(self) -> str:
        """Plaintext version of the event's content."""

        if isinstance(self.source, nio.RoomMessageText):
            return self.source.body

        return strip_html_tags(self.content)

    @staticmethod
    def parse_links(text: str) -> List[str]:
        """Return list of URLs (`<a href=...>` tags) present in the text."""

        ignore = []

        if "<mx-reply>" in text:
            parser = lxml.html.etree.HTMLParser()
            tree   = lxml.etree.fromstring(text, parser)  # nosec
            xpath  = "//mx-reply/blockquote/a[count(preceding-sibling::*)<=1]"
            ignore = [lxml.etree.tostring(el) for el in tree.xpath(xpath)]

        if not text.strip():
            return []

        return [
            url for el, attrib, url, pos in lxml.html.iterlinks(text)
            if lxml.etree.tostring(el) not in ignore
        ]

    def serialized_field(self, field: str) -> Any:
        if field == "source":
            source_dict = asdict(self.source) if self.source else {}
            return json.dumps(source_dict)

        return super().serialized_field(field)
