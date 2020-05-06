# SPDX-License-Identifier: LGPL-3.0-or-later

from typing import TYPE_CHECKING, Any, Collection, Dict, Optional, Tuple

from . import SyncId
from .model import Model
from .proxy import ModelProxy

if TYPE_CHECKING:
    from .model_item import ModelItem


class ModelFilter(ModelProxy):
    def __init__(self, sync_id: SyncId) -> None:
        self.filtered_out: Dict[Tuple[Optional[SyncId], str], "ModelItem"] = {}
        super().__init__(sync_id)


    def accept_item(self, item: "ModelItem") -> bool:
        return True


    def source_item_set(
        self,
        source: Model,
        key,
        value: "ModelItem",
        _changed_fields: Optional[Dict[str, Any]] = None,
    ) -> None:
        if self.accept_source(source):
            if self.accept_item(value):
                self.__setitem__((source.sync_id, key), value, _changed_fields)
                self.filtered_out.pop((source.sync_id, key), None)
            else:
                self.filtered_out[source.sync_id, key] = value
                self.pop((source.sync_id, key), None)


    def source_item_deleted(self, source: Model, key) -> None:
        if self.accept_source(source):
            try:
                del self[source.sync_id, key]
            except KeyError:
                del self.filtered_out[source.sync_id, key]


    def source_cleared(self, source: Model) -> None:
        if self.accept_source(source):
            for source_sync_id, key in self.copy():
                if source_sync_id == source.sync_id:
                    try:
                        del self[source.sync_id, key]
                    except KeyError:
                        del self.filtered_out[source.sync_id, key]


    def refilter(self) -> None:
        take_out   = []
        bring_back = []

        for key, item in sorted(self.items(), key=lambda kv: kv[1]):
            if not self.accept_item(item):
                take_out.append(key)

        for key, item in self.filtered_out.items():
            if self.accept_item(item):
                bring_back.append(key)

        with self.batch_remove():
            for key in take_out:
                self.filtered_out[key] = self.pop(key)

        for key in bring_back:
            self[key] = self.filtered_out.pop(key)


class FieldSubstringFilter(ModelFilter):
    def __init__(self, sync_id: SyncId, fields: Collection[str]) -> None:
        self.fields:  Collection[str] = fields
        self._filter: str             = ""

        super().__init__(sync_id)


    @property
    def filter(self) -> str:
        return self._filter


    @filter.setter
    def filter(self, value: str) -> None:
        self._filter = value
        self.refilter()


    def accept_item(self, item: "ModelItem") -> bool:
        if not self.filter:
            return True

        text       = " ".join((getattr(item, f) for f in self.fields))
        filt       = self.filter
        filt_lower = filt.lower()

        if filt_lower == filt:
            # Consider case only if filter isn't all lowercase (smart case)
            filt = filt_lower
            text = text.lower()

        for word in filt.split():
            if word and word not in text:
                return False

        return True
