# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

from typing import Tuple, Type, Union

from .model_item import ModelItem

# Type[ModelItem] or Tuple[Type[ModelItem], str...]
SyncId = Union[Type[ModelItem], Tuple[Union[Type[ModelItem], str], ...]]
