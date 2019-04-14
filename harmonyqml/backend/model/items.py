# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from typing import Dict, List, NamedTuple, Optional

from PyQt5.QtCore import QDateTime


class User(NamedTuple):
    user_id:        str
    display_name:   str
    avatar_url:     Optional[str] = None
    status_message: Optional[str] = None


class Room(NamedTuple):
    room_id:      str
    display_name: Optional[str]
    description:  str       = ""
    typing_users: List[str] = []


class RoomEvent(NamedTuple):
    type:      str
    date_time: QDateTime
    dict:      Dict[str, str]
