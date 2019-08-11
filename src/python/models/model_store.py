from typing import Dict, Iterator, MutableMapping, Set, Tuple, Type, Union

from dataclasses import dataclass, field

from . import SyncId
from .model_item import ModelItem
from .model import Model

KeyType = Union[Type[ModelItem], Tuple[Type, ...]]

@dataclass(frozen=True)
class ModelStore(MutableMapping):
    allowed_key_types: Set[KeyType] = field()

    data: Dict[SyncId, Model] = field(init=False, default_factory=dict)


    def __getitem__(self, key: SyncId) -> Model:
        try:
            return self.data[key]
        except KeyError:
            if isinstance(key, tuple):
                for i in key:
                    if not i:
                        raise ValueError(f"Empty string in key: {key!r}")

                key_type  = (key[0],) + \
                            tuple(type(el) for el in key[1:])  # type: ignore
            else:
                key_type = key  # type: ignore

            if key_type not in self.allowed_key_types:
                raise TypeError(f"{key_type!r} not in allowed key types: "
                                f"{self.allowed_key_types!r}")

            model          = Model(key)
            self.data[key] = model
            return model


    def __setitem__(self, key, item) -> None:
        raise NotImplementedError()


    def __delitem__(self, key: SyncId) -> None:
        del self.data[key]


    def __iter__(self) -> Iterator[SyncId]:
        return iter(self.data)


    def __len__(self) -> int:
        return len(self.data)
