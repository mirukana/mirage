# Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
# SPDX-License-Identifier: LGPL-3.0-or-later

import itertools
from bisect import bisect
from contextlib import contextmanager
from threading import RLock
from typing import (
    TYPE_CHECKING, Any, Dict, Iterator, List, MutableMapping, Optional, Tuple,
)

from ..pyotherside_events import ModelCleared, ModelItemDeleted, ModelItemSet
from . import SyncId

if TYPE_CHECKING:
    from .model_item import ModelItem
    from .proxy import ModelProxy  # noqa


class Model(MutableMapping):
    """A mapping of `{ModelItem.id: ModelItem}` synced between Python & QML.

    From the Python side, the model is usable like a normal dict of
    `ModelItem` subclass objects.
    Different types of `ModelItem` must not be mixed in the same model.

    When items are added, replaced, removed, have field value changes, or the
    model is cleared, corresponding `PyOtherSideEvent` are fired to inform
    QML of the changes so that it can keep its models in sync.

    Items in the model are kept sorted using the `ModelItem` subclass `__lt__`.
    """

    instances: Dict[SyncId, "Model"]      = {}
    proxies:   Dict[SyncId, "ModelProxy"] = {}


    def __init__(self, sync_id: Optional[SyncId]) -> None:
        self.sync_id:      Optional[SyncId]       = sync_id
        self.write_lock:   RLock                  = RLock()
        self._data:        Dict[Any, "ModelItem"] = {}
        self._sorted_data: List["ModelItem"]      = []

        self.take_items_ownership: bool = True

        # [(index, item.id), ...]
        self._active_batch_removed: Optional[List[Tuple[int, Any]]] = None

        if self.sync_id:
            self.instances[self.sync_id] = self


    def __repr__(self) -> str:
        """Provide a full representation of the model and its content."""

        try:
            from pprintpp import pformat
        except ImportError:
            from pprint import pformat  # type: ignore

        return "%s(sync_id=%s, %s)" % (
            type(self).__name__, self.sync_id, pformat(self._data),
        )


    def __str__(self) -> str:
        """Provide a short "<sync_id>: <num> items" representation."""
        return f"{self.sync_id}: {len(self)} items"


    def __getitem__(self, key):
        return self._data[key]


    def __setitem__(
        self,
        key,
        value: "ModelItem",
        _changed_fields: Optional[Dict[str, Any]] = None,
    ) -> None:
        with self.write_lock:
            existing = self._data.get(key)
            new      = value

            # Collect changed fields

            changed_fields = _changed_fields or {}

            if not changed_fields:
                for field in new.__dataclass_fields__:  # type: ignore
                    changed = True

                    if existing:
                        changed = \
                            getattr(new, field) != getattr(existing, field)

                    if changed:
                        changed_fields[field] = new.serialize_field(field)

            # Set parent model on new item

            if self.sync_id and self.take_items_ownership:
                new.parent_model = self

            # Insert into sorted data

            index_then = None

            if existing:
                index_then = self._sorted_data.index(existing)
                del self._sorted_data[index_then]

            index_now = bisect(self._sorted_data, new)
            self._sorted_data.insert(index_now, new)

            # Insert into dict data

            self._data[key] = new

            # Callbacks

            for sync_id, proxy in self.proxies.items():
                if sync_id != self.sync_id:
                    proxy.source_item_set(self, key, value)

            # Emit PyOtherSide event

            if self.sync_id and (index_then != index_now or changed_fields):
                ModelItemSet(
                    self.sync_id, index_then, index_now, changed_fields,
                )


    def __delitem__(self, key) -> None:
        with self.write_lock:
            item = self._data[key]

            if self.sync_id and self.take_items_ownership:
                item.parent_model = None

            del self._data[key]

            index = self._sorted_data.index(item)
            del self._sorted_data[index]

            for sync_id, proxy in self.proxies.items():
                if sync_id != self.sync_id:
                    proxy.source_item_deleted(self, key)

            if self.sync_id:
                if self._active_batch_removed is None:
                    ModelItemDeleted(self.sync_id, index, 1, (item.id,))
                else:
                    self._active_batch_removed.append((index, item.id))


    def __iter__(self) -> Iterator:
        return iter(self._data)


    def __len__(self) -> int:
        return len(self._data)


    def __lt__(self, other: "Model") -> bool:
        """Sort `Model` objects lexically by `sync_id`."""
        return str(self.sync_id) < str(other.sync_id)


    def clear(self) -> None:
        super().clear()
        if self.sync_id:
            ModelCleared(self.sync_id)


    def copy(self, sync_id: Optional[SyncId] = None) -> "Model":
        new = type(self)(sync_id=sync_id)
        new.update(self)
        return new


    @contextmanager
    def batch_remove(self):
        """Context manager that accumulates item removal events.

        When the context manager exits, sequences of removed items are grouped
        and one `ModelItemDeleted` pyotherside event is fired per sequence.
        """

        with self.write_lock:
            try:
                self._active_batch_removed = []
                yield None
            finally:
                batch  = self._active_batch_removed
                groups = [
                    list(group) for item, group in
                    itertools.groupby(batch, key=lambda x: x[0])
                ]

                for group in groups:
                    ModelItemDeleted(
                        self.sync_id,
                        index = group[0][0],
                        count = len(group),
                        ids   = [item[1] for item in group],
                    )

                self._active_batch_removed = None
