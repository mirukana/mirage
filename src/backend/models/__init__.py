"""Provide classes related to data models shared between Python and QML."""

from typing import Tuple, Type, Union

from .model_item import ModelItem

# last one: Tuple[Union[Type[ModelItem], Tuple[Type[ModelItem]]], str...]
SyncId = Union[Type[ModelItem], Tuple[Type[ModelItem]], tuple]
