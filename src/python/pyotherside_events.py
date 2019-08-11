# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Union

from . import pyotherside
from .models import SyncId


@dataclass
class PyOtherSideEvent:
    def __post_init__(self) -> None:
        # CPython >= 3.6 or any Python >= 3.7 needed for correct dict order
        args = [
            self._process_field(getattr(self, field))
            for field in self.__dataclass_fields__  # type: ignore
        ]
        pyotherside.send(type(self).__name__, *args)


    @staticmethod
    def _process_field(value: Any) -> Any:
        if hasattr(value, "__class__") and issubclass(value.__class__, Enum):
            return value.value

        return value


@dataclass
class ExitRequested(PyOtherSideEvent):
    exit_code: int = 0


@dataclass
class CoroutineDone(PyOtherSideEvent):
    uuid:   str = field()
    result: Any = None


@dataclass
class ModelUpdated(PyOtherSideEvent):
    sync_id: SyncId               = field()
    data:    List[Dict[str, Any]] = field()

    serialized_sync_id: Union[str, List[str]] = field(init=False)

    def __post_init__(self) -> None:
        if isinstance(self.sync_id, tuple):
            self.serialized_sync_id = [
                e.__name__ if isinstance(e, type) else e for e in self.sync_id
            ]
        else:
           self.serialized_sync_id = self.sync_id.__name__

        super().__post_init__()
