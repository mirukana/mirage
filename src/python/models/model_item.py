from typing import Any, Dict, Optional


class ModelItem:
    def __new__(cls, *_args, **_kwargs) -> "ModelItem":
        from .model import Model
        cls.parent_model: Optional[Model] = None
        return super().__new__(cls)


    def __setattr__(self, name: str, value) -> None:
        super().__setattr__(name, value)

        if name != "parent_model" and self.parent_model is not None:
            with self.parent_model._sync_lock:
                self.parent_model._changed = True


    def __delattr__(self, name: str) -> None:
        raise NotImplementedError()


    @property
    def serialized(self) -> Dict[str, Any]:
        return {
            name: getattr(self, name) for name in dir(self)
            if not (
                name.startswith("_") or name in ("parent_model", "serialized")
            )
        }
