# SPDX-License-Identifier: LGPL-3.0-or-later

from typing import Any, Dict, Optional

from ..utils import serialize_value_for_qml


class ModelItem:
    """Base class for items stored inside a `Model`.

    This class must be subclassed and not used directly.
    All subclasses must be dataclasses.

    Subclasses are also expected to implement `__lt__()`,
    to provide support for comparisons with the `<`, `>`, `<=`, `=>` operators
    and thus allow a `Model` to sort its `ModelItem`s.

    They may also implement a `filter_string` property, that will be used
    for filtering from the UI.
    """

    def __new__(cls, *_args, **_kwargs) -> "ModelItem":
        from .model import Model
        cls.parent_model: Optional[Model] = None
        return super().__new__(cls)


    def __setattr__(self, name: str, value) -> None:
        """If this item is in a `Model`, alert it of attribute changes."""

        super().__setattr__(name, value)

        if name != "parent_model" and self.parent_model is not None:
            with self.parent_model._sync_lock:
                self.parent_model._changed = True


    def __delattr__(self, name: str) -> None:
        raise NotImplementedError()


    @property
    def serialized(self) -> Dict[str, Any]:
        """Return this item as a dict ready to be passed to QML."""

        return {
            name: serialize_value_for_qml(getattr(self, name))
            for name in dir(self)
            if not (
                name.startswith("_") or name in ("parent_model", "serialized")
            )
        }
