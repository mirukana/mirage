# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

from enum import Enum
from enum import auto as autostr

auto = autostr  # pylint: disable=invalid-name


class AutoStrEnum(Enum):
    @staticmethod
    def _generate_next_value_(name, *_):
        return name
