from typing import Any, Dict, List, Optional

from PyQt5.QtCore import QDateTime

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

    roomId:      str           = ""
    displayName: str           = ""
    topic:       Optional[str] = None
    typingUsers: List[str]     = []

    inviter:   Optional[Dict[str, str]] = None
    leftEvent: Optional[Dict[str, str]] = None


class RoomCategory(ListItem):
    _required_init_values = {"name", "rooms"}
    _constant             = {"rooms"}

    name: str = ""

    # Must be provided at init, else it will be the same object
    # for every RoomCategory
    rooms: ListModel = ListModel()


class Account(ListItem):
    _required_init_values = {"userId", "roomCategories"}
    _constant             = {"userId", "roomCategories"}

    userId:         str           = ""
    roomCategories: ListModel     = ListModel()  # same as RoomCategory.rooms
    displayName:    Optional[str] = None
    avatarUrl:      Optional[str] = None
    statusMessage:  Optional[str] = None
