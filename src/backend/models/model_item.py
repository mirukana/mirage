# SPDX-License-Identifier: LGPL-3.0-or-later

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any, Dict, Optional

from ..pyotherside_events import ModelItemSet
from ..utils import serialize_value_for_qml

if TYPE_CHECKING:
    from .model import Model


@dataclass
class ModelItem:
    """Base class for items stored inside a `Model`.

    This class must be subclassed and not used directly.
    All subclasses must be dataclasses.

    Subclasses are also expected to implement `__lt__()`,
    to provide support for comparisons with the `<`, `>`, `<=`, `=>` operators
    and thus allow a `Model` to keep its data sorted.
    """

    id: Any = field()


    def __new__(cls, *_args, **_kwargs) -> "ModelItem":
        cls.parent_model: Optional[Model] = None
        return super().__new__(cls)


    def __setattr__(self, name: str, value) -> None:
        """If this item is in a `Model`, alert it of attribute changes."""

        if name == "parent_model" or not self.parent_model:
            super().__setattr__(name, value)
            return

        if getattr(self, name) == value:
            return

        super().__setattr__(name, value)

        parent = self.parent_model

        if not parent.sync_id:
            return

        fields = {name: self.serialize_field(name)}

        with parent._write_lock:
            index_then = parent._sorted_data.index(self)
            parent._sorted_data.sort()
            index_now = parent._sorted_data.index(self)

            ModelItemSet(parent.sync_id, index_then, index_now, fields)

        for sync_id, proxy in parent.proxies.items():
            if sync_id != parent.sync_id:
                proxy.source_item_set(parent, self.id, self, fields)


    def __delattr__(self, name: str) -> None:
        raise NotImplementedError()


    def serialize_field(self, field: str) -> Any:
        return serialize_value_for_qml(
            getattr(self, field),
            json_list_dicts=True,
        )


    @property
    def serialized(self) -> Dict[str, Any]:
        """Return this item as a dict ready to be passed to QML."""

        return {
            name: self.serialize_field(name) for name in dir(self)
            if not (
                name.startswith("_") or name in ("parent_model", "serialized")
            )
        }
