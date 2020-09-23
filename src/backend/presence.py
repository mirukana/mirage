# Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
# SPDX-License-Identifier: LGPL-3.0-or-later

from dataclasses import dataclass, field
from datetime import datetime
from typing import TYPE_CHECKING, Any, Dict, Optional

from .utils import AutoStrEnum, auto

if TYPE_CHECKING:
    from .models.items import Account, Member

ORDER: Dict[str, int] = {
    "online":      0,
    "unavailable": 1,
    "offline":     2,
}


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
            return ORDER[self.value] < ORDER[other.value]


    presence:         State    = State.offline
    currently_active: bool     = False
    last_active_at:   datetime = datetime.fromtimestamp(0)
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
