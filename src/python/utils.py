# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

import collections
from enum import auto as autostr
from enum import Enum

auto = autostr  # pylint: disable=invalid-name


class AutoStrEnum(Enum):
    @staticmethod
    def _generate_next_value_(name, *_):
        return name


def dict_update_recursive(dict1, dict2):
    # https://gist.github.com/angstwad/bf22d1822c38a92ec0a9
    for k in dict2:
        if (k in dict1 and isinstance(dict1[k], dict) and
                isinstance(dict2[k], collections.Mapping)):
            dict_update_recursive(dict1[k], dict2[k])
        else:
            dict1[k] = dict2[k]
