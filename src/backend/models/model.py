# SPDX-License-Identifier: LGPL-3.0-or-later

from bisect import bisect
from threading import RLock
from typing import TYPE_CHECKING, Any, Dict, Iterator, List, MutableMapping

from blist import blist

from ..pyotherside_events import (
    ModelCleared, ModelItemDeleted, ModelItemInserted,
)
from . import SyncId

if TYPE_CHECKING:
    from .model_item import ModelItem


class Model(MutableMapping):
    """A mapping of `{identifier: ModelItem}` synced between Python & QML.

    From the Python side, the model is usable like a normal dict of
    `ModelItem` subclass objects.
    Different types of `ModelItem` must not be mixed in the same model.

    When items are added, changed or removed from the model, a synchronization
    with QML is scheduled.
    The model will synchronize with QML no more than every 0.25s, for
    performance reasons; though it is possible to request an instant sync
    via `sync_now()` for certain cases when this delay is unacceptable.

    Model data is sent to QML using a `ModelUpdated` event from the
    `pyotherside_events` module.
    The data is a list of serialized `ModelItem` dicts, as expected
    by QML for components like `ListView`.
    """

    def __init__(self, sync_id: SyncId) -> None:
        self.sync_id:      SyncId                 = sync_id
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

            new.parent_model = self

            self._data[key] = new
            index           = bisect(self._sorted_data, new)
            self._sorted_data.insert(index, new)

            ModelItemInserted(self.sync_id, index, new)


    def __delitem__(self, key) -> None:
        with self._write_lock:
            item  = self._data.pop(key)
            index = self._sorted_data.index(item)
            del self._sorted_data[index]
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
        ModelCleared(self.sync_id)
