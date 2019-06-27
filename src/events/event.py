from enum import Enum

from dataclasses import dataclass

import pyotherside


class AutoStrEnum(Enum):
    @staticmethod
    def _generate_next_value_(name, *_):
        return name


@dataclass
class Event:
    def __post_init__(self) -> None:
        # CPython >= 3.6 or any Python >= 3.7 needed for correct dict order
        args = [
            # pylint: disable=no-member
            getattr(self, field)
            for field in self.__dataclass_fields__  # type: ignore
        ]
        pyotherside.send(type(self).__name__, *args)
