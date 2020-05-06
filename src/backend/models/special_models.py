# SPDX-License-Identifier: LGPL-3.0-or-later

from .filters import FieldSubstringFilter
from .model import Model


class AllRooms(FieldSubstringFilter):
    def __init__(self) -> None:
        super().__init__(sync_id="all_rooms", fields=("display_name",))


    def accept_source(self, source: Model) -> bool:
        return (
            isinstance(source.sync_id, tuple) and
            len(source.sync_id) == 2 and
            source.sync_id[1] == "rooms"  # type: ignore
        )
