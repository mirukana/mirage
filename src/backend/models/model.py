import logging as log
import time
from threading import Lock, Thread
from typing import Any, Dict, Iterator, List, MutableMapping

from . import SyncId
from ..pyotherside_events import ModelUpdated
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
        self.sync_id:  SyncId               = sync_id
        self._data:    Dict[Any, ModelItem] = {}

        self._changed:     bool   = False
        self._sync_lock:   Lock   = Lock()
        self._sync_thread: Thread = Thread(target=self._sync_loop, daemon=True)
        self._sync_thread.start()


    def __repr__(self) -> str:
        """Provide a full representation of the model and its content."""

        try:
            from pprintpp import pformat
        except ImportError:
            from pprint import pformat  # type: ignore

        if isinstance(self.sync_id, tuple):
            sid = (self.sync_id[0].__name__, *self.sync_id[1:])
        else:
            sid = self.sync_id.__name__  # type: ignore

        return "%s(sync_id=%s, %s)" % (
            type(self).__name__, sid, pformat(self._data),
        )


    def __str__(self) -> str:
        """Provide a short "<sync_id>: <num> items" representation."""

        if isinstance(self.sync_id, tuple):
            reprs = tuple(repr(s) for s in self.sync_id[1:])
            sid = ", ".join((self.sync_id[0].__name__, *reprs))
            sid = f"({sid})"
        else:
            sid = self.sync_id.__name__

        return f"{sid!s}: {len(self)} items"


    def __getitem__(self, key):
        return self._data[key]


    def __setitem__(self, key, value: ModelItem) -> None:
        """Merge new item with an existing one if possible, else add it.

        If an existing item with the passed `key` is found, its fields will be
        updated with the passed `ModelItem`'s fields.
        In other cases, the item is simply added to the model.

        This also sets the `ModelItem.parent_model` hidden attribute on the
        passed item.
        """

        new = value

        if key in self:
            existing = dict(self[key].serialized)  # copy to not alter with pop
            merged   = {**existing, **value.serialized}

            existing.pop("parent_model", None)
            merged.pop("parent_model", None)

            if merged == existing:
                return

            merged_init_kwargs = {**vars(self[key]), **vars(value)}
            merged_init_kwargs.pop("parent_model", None)
            new = type(value)(**merged_init_kwargs)

        new.parent_model = self

        with self._sync_lock:
            self._data[key] = new
            self._changed   = True


    def __delitem__(self, key) -> None:
        with self._sync_lock:
            del self._data[key]
            self._changed = True


    def __iter__(self) -> Iterator:
        return iter(self._data)


    def __len__(self) -> int:
        return len(self._data)


    def _sync_loop(self) -> None:
        """Loop to synchronize model when needed with a cooldown of 0.25s."""

        while True:
            time.sleep(0.25)

            if self._changed:
                with self._sync_lock:
                    log.debug("Syncing %s", self)
                    self.sync_now()


    def sync_now(self) -> None:
        """Trigger a model synchronization right now. Use with precaution."""

        ModelUpdated(self.sync_id, self.serialized())
        self._changed = False


    def serialized(self) -> List[Dict[str, Any]]:
        """Return serialized model content as a list of dict for QML."""

        return [item.serialized for item in sorted(self._data.values())]


    def __lt__(self, other: "Model") -> bool:
        """Sort `Model` objects lexically by `sync_id`."""
        return str(self.sync_id) < str(other.sync_id)
