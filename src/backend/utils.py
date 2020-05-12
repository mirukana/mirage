# SPDX-License-Identifier: LGPL-3.0-or-later

"""Various utilities that are used throughout the package."""

import collections
import html
import inspect
import io
import json
import sys
import xml.etree.cElementTree as xml_etree  # FIXME: bandit warning
from datetime import datetime, timedelta
from enum import Enum
from enum import auto as autostr
from pathlib import Path
from tempfile import NamedTemporaryFile
from types import ModuleType
from typing import (
    Any, AsyncIterator, Callable, Dict, Mapping, Sequence, Tuple, Type, Union,
)
from uuid import UUID

import aiofiles
import filetype
from aiofiles.threadpool.binary import AsyncBufferedReader
from aiofiles.threadpool.text import AsyncTextIOWrapper
from nio.crypto import AsyncDataT as File
from nio.crypto import async_generator_from_data

if sys.version_info >= (3, 7):
    from contextlib import asynccontextmanager
else:
    from async_generator import asynccontextmanager

AsyncOpenFile = Union[AsyncTextIOWrapper, AsyncBufferedReader]
Size          = Tuple[int, int]
auto          = autostr


class AutoStrEnum(Enum):
    """An Enum where auto() assigns the member's name instead of an integer.

    Example:
    >>> class Fruits(AutoStrEnum): apple = auto()
    >>> Fruits.apple.value
    "apple"
    """

    @staticmethod
    def _generate_next_value_(name, *_):
        return name


def dict_update_recursive(dict1: dict, dict2: dict) -> None:
    """Deep-merge `dict1` and `dict2`, recursive version of `dict.update()`."""
    # https://gist.github.com/angstwad/bf22d1822c38a92ec0a9

    for k in dict2:
        if (k in dict1 and isinstance(dict1[k], dict) and
                isinstance(dict2[k], collections.Mapping)):
            dict_update_recursive(dict1[k], dict2[k])
        else:
            dict1[k] = dict2[k]


async def is_svg(file: File) -> bool:
    """Return whether the file is a SVG (`lxml` is used for detection)."""

    chunks = [c async for c in async_generator_from_data(file)]

    with io.BytesIO(b"".join(chunks)) as file:
        try:
            _, element = next(xml_etree.iterparse(file, ("start",)))
            return element.tag == "{http://www.w3.org/2000/svg}svg"
        except (StopIteration, xml_etree.ParseError):
            return False


async def svg_dimensions(file: File) -> Size:
    """Return the width and height, or viewBox width and height for a SVG.

    If these properties are missing (broken file), ``(256, 256)`` is returned.
    """

    chunks = [c async for c in async_generator_from_data(file)]

    with io.BytesIO(b"".join(chunks)) as file:
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


async def guess_mime(file: File) -> str:
    """Return the file's mimetype, or `application/octet-stream` if unknown."""

    if isinstance(file, io.IOBase):
        file.seek(0, 0)
    elif isinstance(file, AsyncBufferedReader):
        await file.seek(0, 0)

    try:
        first_chunk: bytes
        async for first_chunk in async_generator_from_data(file):
            break
        else:
            return "inode/x-empty"  # empty file

        # TODO: plaintext
        mime = filetype.guess_mime(first_chunk)

        return mime or (
            "image/svg+xml" if await is_svg(file) else
            "application/octet-stream"
        )
    finally:
        if isinstance(file, io.IOBase):
            file.seek(0, 0)
        elif isinstance(file, AsyncBufferedReader):
            await file.seek(0, 0)


def plain2html(text: str) -> str:
    """Convert `\\n` into `<br>` tags and `\\t` into four spaces."""

    return html.escape(text)\
               .replace("\n", "<br>")\
               .replace("\t", "&nbsp;" * 4)


def serialize_value_for_qml(value: Any, json_list_dicts: bool = False) -> Any:
    """Convert a value to make it easier to use from QML.

    Returns:

    - For `int`, `float`, `bool`, `str` and `datetime`: the unchanged value

    - For `Sequence` and `Mapping` subclasses (includes `list` and `dict`):
      a JSON dump if `json_list_dicts` is `True`, else the unchanged value

    - If the value is an instancied object and has a `serialized` attribute or
      property, return that

    - For `Enum` members, the actual value of the member

    - For `Path` objects, a `file://<path...>` string

    - For `UUID` object: the UUID in string form

    - For `timedelta` objects: the delta as a number of milliseconds `int`

    - For class types: the class `__name__`

    - For anything else: the unchanged value
    """

    if isinstance(value, (int, float, bool, str, datetime)):
        return value

    if json_list_dicts and isinstance(value, (Sequence, Mapping)):
        return json.dumps(value)

    if not inspect.isclass(value) and hasattr(value, "serialized"):
        return value.serialized

    if hasattr(value, "__class__") and issubclass(value.__class__, Enum):
        return value.value

    if isinstance(value, Path):
        return f"file://{value!s}"

    if isinstance(value, UUID):
        return str(value)

    if isinstance(value, timedelta):
        return value.total_seconds() * 1000

    if inspect.isclass(value):
        return value.__name__

    return value


def classes_defined_in(module: ModuleType) -> Dict[str, Type]:
    """Return a `{name: class}` dict of all the classes a module defines."""

    return {
        m[0]: m[1] for m in inspect.getmembers(module, inspect.isclass)
        if not m[0].startswith("_") and
        m[1].__module__.startswith(module.__name__)
    }


@asynccontextmanager
async def atomic_write(
    path: Union[Path, str], binary: bool = False, **kwargs,
) -> AsyncIterator[Tuple[AsyncOpenFile, Callable[[], None]]]:
    """Write a file asynchronously (using aiofiles) and atomically.

    Yields a `(open_temporary_file, done_function)` tuple.
    The done function should be called after writing to the given file.
    When the context manager exits, the temporary file will either replace
    `path` if the function was called, or be deleted.

    Example:
    >>> async with atomic_write("foo.txt") as (file, done):
    >>>     await file.write("Sample text")
    >>>     done()
    """

    mode      = "wb" if binary else "w"
    path      = Path(path)
    temp      = NamedTemporaryFile(dir=path.parent, delete=False)
    temp_path = Path(temp.name)

    can_replace = False

    def done() -> None:
        nonlocal can_replace
        can_replace = True

    try:
        async with aiofiles.open(temp_path, mode, **kwargs) as out:
            yield (out, done)
    finally:
        if can_replace:
            temp_path.replace(path)
        else:
            temp_path.unlink()
