# SPDX-License-Identifier: LGPL-3.0-or-later

from bisect import bisect
from threading import RLock
from typing import (
    TYPE_CHECKING, Any, Dict, Iterator, List, MutableMapping, Optional,
)

from blist import blist

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
        self._data:        Dict[Any, "ModelItem"] = {}
        self._sorted_data: List["ModelItem"]      = blist()
        self._write_lock:  RLock                  = RLock()


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


    def __setitem__(self, key, value: "ModelItem") -> None:
        with self._write_lock:
            existing = self._data.get(key)
            new      = value

            # Collect changed fields

            changed_fields = {}

            for field in new.__dataclass_fields__:  # type: ignore
                changed = True

                if existing:
                    changed = getattr(new, field) != getattr(existing, field)

                if changed:
                    changed_fields[field] = new.serialize_field(field)

            # Set parent model on new item

            if self.sync_id:
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

            # Emit PyOtherSide event

            if self.sync_id and (index_then != index_now or changed_fields):
                ModelItemSet(
                    self.sync_id, index_then, index_now, changed_fields,
                )


    def __delitem__(self, key) -> None:
        with self._write_lock:
            item = self._data[key]

            if self.sync_id:
                item.parent_model = None

            del self._data[key]

            index = self._sorted_data.index(item)
            del self._sorted_data[index]

            if self.sync_id:
                ModelItemDeleted(self.sync_id, index)


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
