from enum import Enum
from typing import Any, Dict, List, Optional

from PyQt5.QtCore import QDateTime, QSortFilterProxyModel

from .list_item import ListItem
from .list_model import ListModel


class RoomEvent(ListItem):
    _required_init_values = {"type", "dict"}
    _constant             = {"type"}

    type:        str            = ""
    dict:        Dict[str, Any] = {}
    dateTime:    QDateTime      = QDateTime.currentDateTime()
    isLocalEcho: bool           = False


class Room(ListItem):
    _required_init_values = {"roomId", "displayName"}
    _constant             = {"roomId"}

    roomId:            str                 = ""
    displayName:       str                 = ""
    topic:             Optional[str]       = None
    typingUsers:       List[str]           = []
    lastEventDateTime: Optional[QDateTime] = None

    inviter:   Optional[Dict[str, str]] = None
    leftEvent: Optional[Dict[str, str]] = None


class RoomCategory(ListItem):
    _required_init_values = {"name", "rooms", "sortedRooms"}
    _constant             = {"rooms", "sortedRooms"}

    name: str = ""

    # Must be provided at init, else it will be the same object
    # for every RoomCategory
    rooms:       ListModel             = ListModel()
    sortedRooms: QSortFilterProxyModel = QSortFilterProxyModel()


class Trust(Enum):
    blacklisted = -1
    undecided   = 0
    trusted     = 1


class Device(ListItem):
    _required_init_values = {"deviceId", "ed25519Key"}
    _constant             = {"deviceId", "ed25519Key"}

    deviceId:    str           = ""
    ed25519Key:  str           = ""
    displayName: Optional[str] = None
    trust:       Trust         = Trust.undecided


class Account(ListItem):
    _required_init_values = {"userId", "roomCategories"}
    _constant             = {"userId", "roomCategories"}

    userId:         str           = ""
    roomCategories: ListModel     = ListModel()  # same as RoomCategory.rooms
    displayName:    Optional[str] = None
    avatarUrl:      Optional[str] = None
    statusMessage:  Optional[str] = None
