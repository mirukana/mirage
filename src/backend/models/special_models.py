# SPDX-License-Identifier: LGPL-3.0-or-later

from .filters import FieldSubstringFilter, ModelFilter
from .model import Model
from .model_item import ModelItem


class AllRooms(FieldSubstringFilter):
    def __init__(self) -> None:
        super().__init__(sync_id="all_rooms", fields=("display_name",))


    def accept_source(self, source: Model) -> bool:
        return (
            isinstance(source.sync_id, tuple) and
            len(source.sync_id) == 2 and
            source.sync_id[1] == "rooms"  # type: ignore
        )


class MatchingAccounts(ModelFilter):
    def __init__(self, all_rooms: AllRooms) -> None:
        super().__init__(sync_id="matching_accounts")
        self.all_rooms = all_rooms
        self.all_rooms.items_changed_callbacks.append(self.refilter)


    def accept_source(self, source: Model) -> bool:
        return source.sync_id == "accounts"


    def accept_item(self, item: ModelItem) -> bool:
        if not self.all_rooms.filter:
            return True

        return next(
            (r for r in self.all_rooms.values() if r.for_account == item.id),
            False,
        )
