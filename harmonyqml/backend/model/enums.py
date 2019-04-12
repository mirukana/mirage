# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from enum import Enum


class Activity(Enum):
    none          = 0
    focus         = 1
    paused_typing = 2
    typing        = 3


class Presence(Enum):
    none      = 0
    offline   = 1
    invisible = 2
    away      = 3
    busy      = 4
    online    = 5


class MessageKind(Enum):
    audio    = "m.audio"
    emote    = "m.emote"
    file     = "m.file"
    image    = "m.image"
    location = "m.location"
    notice   = "m.notice"
    text     = "m.text"
    video    = "m.video"
