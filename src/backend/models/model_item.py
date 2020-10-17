# Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
# SPDX-License-Identifier: LGPL-3.0-or-later

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any, Dict, Optional

from ..pyotherside_events import ModelItemSet
from ..utils import serialize_value_for_qml

if TYPE_CHECKING:
    from .model import Model


@dataclass(eq=False)
class ModelItem:
    """Base class for items stored inside a `Model`.

    This class must be subclassed and not used directly.
    All subclasses must use the `@dataclass(eq=False)` decorator.

    Subclasses are also expected to implement `__lt__()`,
    to provide support for comparisons with the `<`, `>`, `<=`, `=>` operators
    and thus allow a `Model` to keep its data sorted.

    Make sure to respect SortedList requirements when implementing `__lt__()`:
    http://www.grantjenks.com/docs/sortedcontainers/introduction.html#caveats
    """

    id: Any = field()


    def __new__(cls, *_args, **_kwargs) -> "ModelItem":
        cls.parent_model: Optional[Model] = None
        return super().__new__(cls)


    def __setattr__(self, name: str, value) -> None:
        self.set_fields(**{name: value})


    def __delattr__(self, name: str) -> None:
        raise NotImplementedError()


    @property
    def serialized(self) -> Dict[str, Any]:
        """Return this item as a dict ready to be passed to QML."""

        return {
            name: self.serialized_field(name)
            for name in self.__dataclass_fields__  # type: ignore
        }


    def serialized_field(self, field: str) -> Any:
        """Return a field's value in a form suitable for passing to QML."""

        value = getattr(self, field)
        return serialize_value_for_qml(value, json_list_dicts=True)


    def set_fields(self, _force: bool = False, **fields: Any) -> None:
        """Set one or more field's value and call `ModelItem.notify_change`.

        For efficiency, to change multiple fields, this method should be
        used rather than setting them one after another with `=` or `setattr`.
        """

        parent = self.parent_model

        # If we're currently being created or haven't been put in a model yet:
        if not parent:
            for name, value in fields.items():
                super().__setattr__(name, value)
            return

        with parent.write_lock:
            qml_changes = {}
            changes     = {
                name: value for name, value in fields.items()
                if _force or getattr(self, name) != value
            }

            if not changes:
                return

            # To avoid corrupting the SortedList, we have to take out the item,
            # apply the field changes, *then* add it back in.

            index_then = parent._sorted_data.index(self)
            del parent._sorted_data[index_then]

            for name, value in changes.items():
                super().__setattr__(name, value)

                if name in self.__dataclass_fields__:  # type: ignore
                    qml_changes[name] = self.serialized_field(name)

            parent._sorted_data.add(self)
            index_now = parent._sorted_data.index(self)

            # Now, inform QML about changed dataclass fields if any.

            if not parent.sync_id or not qml_changes:
                return

            ModelItemSet(parent.sync_id, index_then, index_now, qml_changes)

        # Inform any proxy connected to the parent model of the field changes

        for sync_id, proxy in parent.proxies.items():
            if sync_id != parent.sync_id:
                proxy.source_item_set(parent, self.id, self, qml_changes)


    def notify_change(self, *fields: str) -> None:
        """Notify the parent model that fields of this item have changed.

        The model cannot automatically detect changes inside
        object fields, such as list or dicts having their data modified.
        In these cases, this method should be called.
        """

        kwargs           = {name: getattr(self, name) for name in fields}
        kwargs["_force"] = True
        self.set_fields(**kwargs)
