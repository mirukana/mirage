# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from typing import Dict, NamedTuple, Optional

from PyQt5.QtCore import QDateTime

from .enums import Activity, Presence


class User(NamedTuple):
    user_id:        str
    display_name:   str
    avatar_url:     Optional[str] = None
    status_message: Optional[str] = None


class Room(NamedTuple):
    room_id:                    str
    display_name:               Optional[str]
    description:                str           = ""
    unread_messages:            int           = 0
    presence:                   Presence      = Presence.none
    activity:                   Activity      = Activity.none
    last_activity_timestamp_ms: Optional[int] = None
    avatar_url:                 Optional[str] = None


class RoomEvent(NamedTuple):
    type:      str
    date_time: QDateTime
    dict:      Dict[str, str]
