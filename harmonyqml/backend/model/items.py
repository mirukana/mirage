from typing import Any, Dict, List, Optional

from PyQt5.QtCore import QDateTime

from .list_item import ListItem


class User(ListItem):
    _required_init_values = {"userId"}
    _constant             = {"userId"}

    userId:        str           = ""
    displayName:   Optional[str] = None
    avatarUrl:     Optional[str] = None
    statusMessage: Optional[str] = None


class Room(ListItem):
    _required_init_values = {"roomId", "displayName"}
    _constant             = {"roomId"}

    roomId:      str                      = ""
    displayName: str                      = ""
    category:    str                      = "Rooms"
    topic:       Optional[str]            = None
    typingUsers: List[str]                = []
    inviter:     Optional[Dict[str, str]] = None
    leftEvent:   Optional[Dict[str, str]] = None


class RoomEvent(ListItem):
    _required_init_values = {"type", "dict"}
    _constant             = {"type"}

    type:        str            = ""
    dict:        Dict[str, Any] = {}
    dateTime:    QDateTime      = QDateTime.currentDateTime()
    isLocalEcho: bool           = False
