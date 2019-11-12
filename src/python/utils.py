"""Contains various utilities that are used throughout the package."""

import asyncio
import collections
import html
import inspect
import io
import logging as log
import xml.etree.cElementTree as xml_etree  # FIXME: bandit warning
from enum import Enum
from enum import auto as autostr
from pathlib import Path
from types import ModuleType
from typing import IO, Any, Callable, Dict, Tuple, Type, Union

import filetype

File = Union[IO, bytes, str, Path]
Size = Tuple[int, int]
auto = autostr

CANCELLABLE_FUTURES: Dict[Tuple[Any, Callable], asyncio.Future] = {}


class AutoStrEnum(Enum):
    """An Enum where auto() assigns the member's name instead of an int.

    Example:
    >>> class Fruits(AutoStrEnum): apple = auto()
    >>> Fruits.apple.value
    "apple"
    """
    @staticmethod
    def _generate_next_value_(name, *_):
        return name


def dict_update_recursive(dict1: dict, dict2: dict) -> None:
    """Recursive version of dict.update()."""
    # https://gist.github.com/angstwad/bf22d1822c38a92ec0a9

    for k in dict2:
        if (k in dict1 and isinstance(dict1[k], dict) and
                isinstance(dict2[k], collections.Mapping)):
            dict_update_recursive(dict1[k], dict2[k])
        else:
            dict1[k] = dict2[k]


def is_svg(file: File) -> bool:
    """Return True if the file is a SVG. Uses lxml for detection."""

    if isinstance(file, Path):
        file = str(file)

    try:
        _, element = next(xml_etree.iterparse(file, ("start",)))
        return element.tag == "{http://www.w3.org/2000/svg}svg"
    except (StopIteration, xml_etree.ParseError):
        return False


def svg_dimensions(file: File) -> Size:
    """Return the width & height or viewBox width & height for a SVG.
    If these properties are missing (broken file), ``(256, 256)`` is returned.
    """

    if isinstance(file, Path):
        file = str(file)

    attrs = xml_etree.parse(file).getroot().attrib

    try:
        width = round(float(attrs.get("width", attrs["viewBox"].split()[3])))
    except (KeyError, IndexError, ValueError, TypeError):
        width = 256

    try:
        height = round(float(attrs.get("height", attrs["viewBox"].split()[4])))
    except (KeyError, IndexError, ValueError, TypeError):
        height = 256

    return (width, height)


def guess_mime(file: File) -> str:
    """Return the mime type for a file, or application/octet-stream if it
    can't be guessed.
    """

    if is_svg(file):
        return "image/svg+xml"

    if isinstance(file, Path):
        file = str(file)
    elif isinstance(file, io.IOBase):
        file.seek(0, 0)

    try:
        return filetype.guess_mime(file) or "application/octet-stream"
    finally:
        if isinstance(file, io.IOBase):
            file.seek(0, 0)


def plain2html(text: str) -> str:
    """Transform plain text into HTML, this converts \n and \t."""

    return html.escape(text)\
               .replace("\n", "<br>")\
               .replace("\t", "&nbsp;" * 4)


def serialize_value_for_qml(value: Any) -> Any:
    """Transform a value to make it easier to use from QML.

    Currently, this transforms Enum members to their actual value and Path
    objects to their string version.
    """

    if hasattr(value, "__class__") and issubclass(value.__class__, Enum):
        return value.value

    if isinstance(value, Path):
        return f"file://{value!s}"

    return value


def classes_defined_in(module: ModuleType) -> Dict[str, Type]:
    """Return a {name: class} dict of all the classes a module defines."""

    return {
        m[0]: m[1] for m in inspect.getmembers(module, inspect.isclass)
        if not m[0].startswith("_") and
        m[1].__module__.startswith(module.__name__)
    }


def cancel_previous(async_func):
    """When the wrapped coroutine is called, cancel any previous instance
    of that coroutine that may still be running.
    """

    async def wrapper(*args, **kwargs):
        try:
            arg0_is_self = inspect.getfullargspec(async_func).args[0] == "self"
        except IndexError:
            parent_obj = None
        else:
            parent_obj = args[0] if arg0_is_self else None

        previous = CANCELLABLE_FUTURES.get((parent_obj, async_func))
        if previous:
            previous.cancel()
            log.info("Cancelled previous coro: %s", previous)

        future = asyncio.ensure_future(async_func(*args, **kwargs))
        CANCELLABLE_FUTURES[parent_obj, async_func] = future

        try:
            result = await future
            return result
        finally:
            # Make sure to do this even if an exception happens
            del CANCELLABLE_FUTURES[parent_obj, async_func]

    return wrapper
