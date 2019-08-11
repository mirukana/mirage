from typing import Tuple, Type, Union

from .model_item import ModelItem

# Type[ModelItem] or Tuple[Type[ModelItem], str...]
SyncId = Union[Type[ModelItem], Tuple[Union[Type[ModelItem], str], ...]]
