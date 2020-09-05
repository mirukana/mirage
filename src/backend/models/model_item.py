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

        if (
            name == "parent_model" or
            not self.parent_model or
            getattr(self, name) == value
        ):
            super().__setattr__(name, value)
            return

        super().__setattr__(name, value)
        self._notify_parent_model({name: self.serialize_field(name)})


    def _notify_parent_model(self, changed_fields: Dict[str, Any]) -> None:
        parent = self.parent_model

        if not parent or not parent.sync_id or not changed_fields:
            return

        with parent.write_lock:
            index_then = parent._sorted_data.index(self)
            parent._sorted_data.sort()
            index_now = parent._sorted_data.index(self)

            ModelItemSet(parent.sync_id, index_then, index_now, changed_fields)

        for sync_id, proxy in parent.proxies.items():
            if sync_id != parent.sync_id:
                proxy.source_item_set(parent, self.id, self, changed_fields)


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


    def set_fields(self, **fields: Any) -> None:
        """Set multiple fields's values at once.

        The parent model will be resorted only once, and one `ModelItemSet`
        event will be sent informing QML of all the changed fields.
        """

        for name, value in fields.copy().items():
            if getattr(self, name) == value:
                del fields[name]
            else:
                super().__setattr__(name, value)
                fields[name] = self.serialize_field(name)

        self._notify_parent_model(fields)


    def notify_change(self, *fields: str) -> None:
        """Manually notify the parent model that a field changed.

        The model cannot automatically detect changes inside object
        fields, such as list or dicts having their data modified.

        Use this method to manually notify it that such fields were changed,
        and avoid having to reassign the field itself.
        """

        self._notify_parent_model({
            name: self.serialize_field(name) for name in fields
        })
