import logging as log
import time
from threading import Lock, Thread
from typing import Any, Dict, Iterator, List, MutableMapping, Optional

from . import SyncId
from ..pyotherside_events import ModelUpdated
from .model_item import ModelItem


class Model(MutableMapping):
    def __init__(self, sync_id: SyncId) -> None:
        self.sync_id:  SyncId               = sync_id
        self.sortable: Optional[bool]       = None
        self._data:    Dict[Any, ModelItem] = {}

        self._changed:     bool   = False
        self._sync_lock:   Lock   = Lock()
        self._sync_thread: Thread = Thread(target=self._sync_loop, daemon=True)
        self._sync_thread.start()


    def __repr__(self) -> str:
        try:
            from pprintpp import pformat
        except ImportError:
            from pprint import pformat  # type: ignore

        if isinstance(self.sync_id, tuple):
            sid = (self.sync_id[0].__name__, *self.sync_id[1:])  # type: ignore
        else:
            sid = self.sync_id.__name__  # type: ignore

        return "%s(sync_id=%s, sortable=%r, %s)" % (
            type(self).__name__, sid, self.sortable, pformat(self._data),
        )


    def __str__(self) -> str:
        if isinstance(self.sync_id, tuple):
            sid = (self.sync_id[0].__name__, *self.sync_id[1:])  # type: ignore
        else:
            sid = self.sync_id.__name__  # type: ignore

        return f"{sid!s}: {len(self)} items"


    def __getitem__(self, key):
        return self._data[key]


    def __setitem__(self, key, value: ModelItem) -> None:
        new = value

        if key in self:
            existing = dict(self[key].__dict__)  # copy to not alter with pop
            merged   = {**existing, **value.__dict__}

            existing.pop("parent_model", None)
            merged.pop("parent_model", None)

            if merged == existing:
                return

            new = type(value)(**merged)  # type: ignore

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
        while True:
            time.sleep(0.25)

            if self._changed:
                with self._sync_lock:
                    log.debug("Syncing %s", self)
                    ModelUpdated(self.sync_id, self.serialized())
                    self._changed = False


    def serialized(self) -> List[Dict[str, Any]]:
        if self.sortable is True:
            return [item.__dict__ for item in sorted(self._data.values())]

        if self.sortable is False or len(self) < 2:
            return [item.__dict__ for item in self._data.values()]

        try:
            return [item.__dict__ for item in sorted(self._data.values())]
        except TypeError:
            self.sortable = False
        else:
            self.sortable = True

        return self.serialized()
