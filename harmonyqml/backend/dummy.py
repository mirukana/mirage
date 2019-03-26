# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

from PyQt5.QtCore import QDateTime, Qt

from .base import Backend, Message, Room, User


class DummyBackend(Backend):
    def __init__(self) -> None:
        super().__init__()

        dt = lambda t: QDateTime.fromString(f"2019-03-19T{t}.123",
                                            Qt.ISODateWithMs)
        db = lambda t: QDateTime.fromString(f"2019-03-20T{t}.456",
                                            Qt.ISODateWithMs)

        self.accounts.extend([
            User("@renko:matrix.org", "Renko", None, "Sleeping, zzz..."),
            User("@mary:matrix.org", "Mary"),
        ])

        self.rooms["@renko:matrix.org"].extend([
            Room("!test:matrix.org", "Test", "Test room"),
            Room("!mary:matrix.org", "Mary",
                 "Lorem ipsum sit dolor amet this is a long text to test "
                 "wrapping of room subtitle etc 1234 example foo bar abc", 2),
            Room("!foo:matrix.org", "Another room"),
        ])

        self.rooms["@mary:matrix.org"].extend([
            Room("!test:matrix.org", "Test", "Test room"),
            Room("!mary:matrix.org", "Renko", "Lorem ipsum sit dolor amet"),
        ])

        self.messages["!test:matrix.org"].extend([
            Message("@renko:matrix.org", dt("10:20:13"), "Lorem"),
            Message("@renko:matrix.org", dt("10:22:01"), "Ipsum"),
            Message("@renko:matrix.org", dt("10:22:50"), "Combine"),
            Message("@renko:matrix.org", dt("10:30:41"),
                    "Time passed, don't combine"),
            Message("@mary:matrix.org", dt("10:31:12"),
                    "Different person, don't combine"),
            Message("@mary:matrix.org", dt("10:32:04"),
                    "But combine me"),
            Message("@mary:matrix.org", dt("13:10:20"),
                    "Long time passed, conv break"),

            Message("@renko:matrix.org", db("10:22:01"), "Daybreak"),
            Message("@mary:matrix.org", db("10:22:03"),
                    "A longer message to test text wrapping. "
                    "Lorem ipsum dolor sit amet, consectetuer adipiscing "
                    "elit. Aenean commodo ligula "
                    "eget dolor. Aenean massa. Cem sociis natoque penaibs "
                    "et magnis dis parturient montes, nascetur ridiculus "
                    "mus. Donec quam. "),
        ])

        self.messages["!mary:matrix.org"].extend([
            Message("@mary:matrix.org", dt("10:22:23"), "First"),
            Message("@mary:matrix.org", dt("12:24:10"), "Second"),
        ])

        self.messages["!foo:matrix.org"].extend([])
