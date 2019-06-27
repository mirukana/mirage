from typing import Any

from dataclasses import dataclass, field

from .event import Event


@dataclass
class AppExitRequested(Event):
    exit_code: int = 0


@dataclass
class CoroutineDone(Event):
    uuid:   str = field()
    result: Any = None
