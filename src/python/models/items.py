import re
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Type
from uuid import uuid4

import lxml  # nosec

import nio

from ..html_filter import HTML_FILTER
from ..utils import AutoStrEnum, auto
from .model_item import ModelItem


@dataclass
class Account(ModelItem):
    user_id:         str                = field()
    display_name:    str                = ""
    avatar_url:      str                = ""
    first_sync_done: bool               = False
    profile_updated: Optional[datetime] = None

    importing_key:        int                  = 0
    total_keys_to_import: int                  = 0
    import_error:         Tuple[str, str, str] = ("", "", "")  # path,pw,err

    def __lt__(self, other: "Account") -> bool:
        name       = self.display_name or self.user_id[1:]
        other_name = other.display_name or other.user_id[1:]
        return name < other_name

    @property
    def filter_string(self) -> str:
        return self.display_name


@dataclass
class Room(ModelItem):
    room_id:        str       = field()
    display_name:   str       = ""
    avatar_url:     str       = ""
    topic:          str       = ""
    inviter_id:     str       = ""
    inviter_name:   str       = ""
    inviter_avatar: str       = ""
    left:           bool      = False
    typing_members: List[str] = field(default_factory=list)

    # Event.serialized
    last_event: Optional[Dict[str, Any]] = field(default=None, repr=False)

    def __lt__(self, other: "Room") -> bool:
        # Left rooms may still have an inviter_id, check left first.
        if self.left and not other.left:
            return False
        if other.left and not self.left:
            return True

        if self.inviter_id and not other.inviter_id:
            return True
        if other.inviter_id and not self.inviter_id:
            return False

        if self.last_event and other.last_event:
            return self.last_event["date"] > other.last_event["date"]
        if self.last_event and not other.last_event:
            return True
        if other.last_event and not self.last_event:
            return False

        name       = self.display_name or self.room_id
        other_name = other.display_name or other.room_id
        return name < other_name

    @property
    def filter_string(self) -> str:
        return " ".join((
            self.display_name,
            self.topic,
            re.sub(r"<.*?>", "", self.last_event["inline_content"])
            if self.last_event else "",
        ))


@dataclass
class Member(ModelItem):
    user_id:      str  = field()
    display_name: str  = ""
    avatar_url:   str  = ""
    typing:       bool = False
    power_level:  int  = 0

    def __lt__(self, other: "Member") -> bool:
        name       = self.display_name or self.user_id[1:]
        other_name = other.display_name or other.user_id[1:]
        return name < other_name


    @property
    def filter_string(self) -> str:
        return self.display_name


class UploadStatus(AutoStrEnum):
    Starting            = auto()
    Encrypting          = auto()
    Uploading           = auto()
    CreatingThumbnail   = auto()
    EncryptingThumbnail = auto()
    UploadingThumbnail  = auto()
    Failure             = auto()  # TODO


@dataclass
class Upload(ModelItem):
    filepath:   str          = field()
    status:     UploadStatus = UploadStatus.Starting
    total_size: int          = 0
    uploaded:   int          = 0

    uuid:       str = field(init=False, default_factory=lambda: str(uuid4()))
    start_date: datetime = field(init=False, default_factory=datetime.now)


    def __post_init__(self) -> None:
        if not self.total_size:
            self.total_size = Path(self.filepath).resolve().stat().st_size


    def __lt__(self, other: "Upload") -> bool:
        # Sort from newest upload to oldest.
        return self.start_date > other.start_date


class TypeSpecifier(AutoStrEnum):
    none              = auto()
    profile_change    = auto()
    membership_change = auto()


@dataclass
class Event(ModelItem):
    source:        Optional[nio.Event] = field()
    client_id:     str                 = field()
    event_id:      str                 = field()
    date:          datetime            = field()
    sender_id:     str                 = field()
    sender_name:   str                 = field()
    sender_avatar: str                 = field()

    content:        str = ""
    inline_content: str = ""

    type_specifier: TypeSpecifier = TypeSpecifier.none

    target_id:     str = ""
    target_name:   str = ""
    target_avatar: str = ""

    is_local_echo:    bool                      = False
    local_event_type: Optional[Type[nio.Event]] = None

    media_url:        str            = ""
    media_title:      str            = ""
    media_width:      int            = 0
    media_height:     int            = 0
    media_duration:   int            = 0
    media_size:       int            = 0
    media_mime:       str            = ""
    media_crypt_dict: Dict[str, Any] = field(default_factory=dict)

    thumbnail_url:        str            = ""
    thumbnail_width:      int            = 0
    thumbnail_height:     int            = 0
    thumbnail_crypt_dict: Dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if not self.inline_content:
            self.inline_content = HTML_FILTER.filter_inline(self.content)


    def __lt__(self, other: "Event") -> bool:
        # Sort events from newest to oldest. return True means return False.
        return self.date > other.date

    @property
    def event_type(self) -> str:
        if self.local_event_type:
            return self.local_event_type.__name__

        return type(self.source).__name__

    @property
    def links(self) -> List[str]:
        local_type    = self.local_event_type
        media_classes = (nio.RoomMessageMedia, nio.RoomEncryptedMedia)

        if local_type and issubclass(local_type, media_classes):
            return [self.media_url]

        if isinstance(self.source, media_classes):
            return [self.media_url]

        if not self.content.strip():
            return []

        return [link[2] for link in lxml.html.iterlinks(self.content)]


@dataclass
class Device(ModelItem):
    device_id:      str  = field()
    ed25519_key:    str  = field()
    trusted:        bool = False
    blacklisted:    bool = False
    display_name:   str  = ""
    last_seen_ip:   str  = ""
    last_seen_date: str  = ""
