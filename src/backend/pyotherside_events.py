from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Union

import pyotherside

from .models import SyncId
from .utils import serialize_value_for_qml


@dataclass
class PyOtherSideEvent:
    """Event that will be sent on instanciation to QML by PyOtherSide."""

    def __post_init__(self) -> None:
        # CPython 3.6 or any Python implemention >= 3.7 is required for correct
        # __dataclass_fields__ dict order.
        args = [
            serialize_value_for_qml(getattr(self, field))
            for field in self.__dataclass_fields__  # type: ignore
        ]
        pyotherside.send(type(self).__name__, *args)


@dataclass
class ExitRequested(PyOtherSideEvent):
    """Request for the application to exit."""

    exit_code: int = 0


@dataclass
class AlertRequested(PyOtherSideEvent):
    """Request a window manager alert to be shown.

    Sets the urgency hint for compliant X11/Wayland window managers;
    flashes the taskbar icon on Windows.
    """


@dataclass
class CoroutineDone(PyOtherSideEvent):
    """Indicate that an asyncio coroutine finished."""

    uuid:      str                 = field()
    result:    Any                 = None
    exception: Optional[Exception] = None
    traceback: Optional[str]       = None


@dataclass
class ModelUpdated(PyOtherSideEvent):
    """Indicate that a backend model's data changed."""

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
