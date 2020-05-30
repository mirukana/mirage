# SPDX-License-Identifier: LGPL-3.0-or-later

from typing import TYPE_CHECKING, Any, Dict, Optional

from . import SyncId
from .model import Model

if TYPE_CHECKING:
    from .model_item import ModelItem


class ModelProxy(Model):
    """Proxies data from one or more `Model` objects."""

    def __init__(self, sync_id: SyncId) -> None:
        super().__init__(sync_id)
        self.take_items_ownership = False
        Model.proxies[sync_id] = self

        with self.write_lock:
            for sync_id, model in Model.instances.items():
                if sync_id != self.sync_id and self.accept_source(model):
                    for key, item in model.items():
                        self.source_item_set(model, key, item)


    def accept_source(self, source: Model) -> bool:
        """Return whether passed `Model` should be proxied by this proxy."""
        return True


    def convert_item(self, item: "ModelItem") -> "ModelItem":
        """Take a source `ModelItem`, return an appropriate one for proxy.

        By default, this returns the passed item unchanged.

        Due to QML `ListModel` restrictions, if multiple source models
        containing different subclasses of `ModelItem` are proxied,
        they should be converted to a same `ModelItem`
        subclass by overriding this function.
        """
        return item


    def source_item_set(
        self,
        source: Model,
        key,
        value: "ModelItem",
        _changed_fields: Optional[Dict[str, Any]] = None,
    ) -> None:
        """Called when a source model item is added or changed."""

        if self.accept_source(source):
            value = self.convert_item(value)
            self.__setitem__((source.sync_id, key), value, _changed_fields)


    def source_item_deleted(self, source: Model, key) -> None:
        """Called when a source model item is removed."""

        if self.accept_source(source):
            del self[source.sync_id, key]


    def source_cleared(self, source: Model) -> None:
        """Called when a source model is cleared."""

        if self.accept_source(source):
            with self.batch_remove():
                for source_sync_id, key in self.copy():
                    if source_sync_id == source.sync_id:
                        del self[source_sync_id, key]
