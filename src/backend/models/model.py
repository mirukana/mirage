# SPDX-License-Identifier: LGPL-3.0-or-later

from bisect import bisect
from threading import RLock
from typing import (
    TYPE_CHECKING, Any, Dict, Iterator, List, MutableMapping, Optional,
)

from blist import blist

from ..pyotherside_events import (
    ModelCleared, ModelItemDeleted, ModelItemInserted,
)
from . import SyncId

if TYPE_CHECKING:
    from .model_item import ModelItem


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
        """Merge new item with an existing one if possible, else add it.

        If an existing item with the passed `key` is found, its fields will be
        updated with the passed `ModelItem`'s fields.
        In other cases, the item is simply added to the model.

        This also sets the `ModelItem.parent_model` hidden attributes on
        the passed item.
        """

        with self._write_lock:
            existing = self._data.get(key)
            new      = value

            if existing:
                for field in new.__dataclass_fields__:  # type: ignore
                    # The same shared item is in _sorted_data, no need to find
                    # and modify it explicitely.
                    setattr(existing, field, getattr(new, field))
                return

            if self.sync_id:
                new.parent_model = self

            self._data[key] = new
            index           = bisect(self._sorted_data, new)
            self._sorted_data.insert(index, new)

            if self.sync_id:
                ModelItemInserted(self.sync_id, index, new)


    def __delitem__(self, key) -> None:
        with self._write_lock:
            item              = self._data[key]
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


    def get_event_id(self, event_id: str) -> "Model":
        """Get an event from the internal dict by event_id field.

        This function exists because not every event is indexed with its
        event_id field.
        """

        event = self._data.get(event_id)
        if event and event.event_id == event_id:
            return event

        for event in self._data.values():
            if event.event_id == event_id:
                return event

        return None
