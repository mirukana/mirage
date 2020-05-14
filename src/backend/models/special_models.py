# SPDX-License-Identifier: LGPL-3.0-or-later

from dataclasses import asdict
from typing import Set

from .filters import FieldSubstringFilter, ModelFilter
from .items import Account, AccountOrRoom, Room
from .model import Model
from .model_item import ModelItem


class AllRooms(FieldSubstringFilter):
    def __init__(self) -> None:
        super().__init__(sync_id="all_rooms", fields=("display_name",))
        self.items_changed_callbacks.append(self.refilter_accounts)

        self._collapsed: Set[str] = set()


    def set_account_collapse(self, user_id: str, collapsed: bool) -> None:
        def only_if(item):
            return item.type is Room and item.for_account == user_id

        if collapsed and user_id not in self._collapsed:
            self._collapsed.add(user_id)
            self.refilter(only_if)

        if not collapsed and user_id in self._collapsed:
            self._collapsed.remove(user_id)
            self.refilter(only_if)


    def accept_source(self, source: Model) -> bool:
        return source.sync_id == "accounts" or (
            isinstance(source.sync_id, tuple) and
            len(source.sync_id) == 2 and
            source.sync_id[1] == "rooms"  # type: ignore
        )


    def convert_item(self, item: ModelItem) -> AccountOrRoom:
        return AccountOrRoom(**asdict(item), type=type(item))  # type: ignore


    def accept_item(self, item: ModelItem) -> bool:
        assert isinstance(item, AccountOrRoom)  # nosec

        if not self.filter and \
           item.type is Room and \
           item.for_account in self._collapsed:
            return False

        matches_filter = super().accept_item(item)

        if item.type is not Account or not self.filter:
            return matches_filter

        return next(
            (i for i in self.values() if i.for_account == item.id), False,
        )


    def refilter_accounts(self) -> None:
        self.refilter(lambda i: i.type is Account)  # type: ignore


class MatchingAccounts(ModelFilter):
    def __init__(self, all_rooms: AllRooms) -> None:
        self.all_rooms = all_rooms
        self.all_rooms.items_changed_callbacks.append(self.refilter)

        super().__init__(sync_id="matching_accounts")


    def accept_source(self, source: Model) -> bool:
        return source.sync_id == "accounts"


    def accept_item(self, item: ModelItem) -> bool:
        if not self.all_rooms.filter:
            return True

        return next(
            (i for i in self.all_rooms.values() if i.id == item.id),
            False,
        )


class FilteredMembers(FieldSubstringFilter):
    def __init__(self, user_id: str, room_id: str) -> None:
        self.user_id = user_id
        self.room_id = room_id
        sync_id      = (user_id, room_id, "filtered_members")

        super().__init__(sync_id=sync_id, fields=("display_name",))


    def accept_source(self, source: Model) -> bool:
        return source.sync_id == (self.user_id, self.room_id, "members")
