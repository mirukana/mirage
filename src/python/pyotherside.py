# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

import logging as log
from typing import Tuple, Callable

AVAILABLE = True
try:
    import pyotherside
except ModuleNotFoundError:
    log.warning("pyotherside module is unavailable.")
    AVAILABLE = False

Size      = Tuple[int, int]
ImageData = Tuple[bytearray, Size, int]  # last int: pyotherside format enum

format_data:     int = pyotherside.format_data if AVAILABLE else 0
format_svg_data: int = pyotherside.format_svg_data if AVAILABLE else 1
format_rgb888:   int = pyotherside.format_rgb888 if AVAILABLE else 2
format_argb32:   int = pyotherside.format_argb32 if AVAILABLE else 3


def send(event: str, *args) -> None:
    if AVAILABLE:
        pyotherside.send(event, *args)


def set_image_provider(provider: Callable[[str, Size], ImageData]) -> None:
    if AVAILABLE:
        pyotherside.set_image_provider(provider)
