import collections
import html
import inspect
import xml.etree.cElementTree as xml_etree  # FIXME: bandit warning
from enum import Enum
from enum import auto as autostr
from pathlib import Path
from types import ModuleType
from typing import IO, Any, Dict, Tuple, Type, Union

import filetype

auto = autostr


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


def is_svg(file: Union[IO, bytes, str]) -> bool:
    try:
        _, element = next(xml_etree.iterparse(file, ("start",)))
        return element.tag == "{http://www.w3.org/2000/svg}svg"
    except (StopIteration, xml_etree.ParseError):
        return False


def svg_dimensions(file: Union[IO, bytes, str]) -> Tuple[int, int]:
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


def guess_mime(file: IO) -> str:
    if is_svg(file):
        return "image/svg+xml"

    file.seek(0, 0)
    return filetype.guess_mime(file) or "application/octet-stream"


def plain2html(text: str) -> str:
    return html.escape(text)\
               .replace("\n", "<br>")\
               .replace("\t", "&nbsp;" * 4)


def serialize_value_for_qml(value: Any) -> Any:
    if hasattr(value, "__class__") and issubclass(value.__class__, Enum):
        return value.value

    if isinstance(value, Path):
        return f"file://{value!s}"

    return value


def classes_defined_in(module: ModuleType) -> Dict[str, Type]:
    return {
        m[0]: m[1] for m in inspect.getmembers(module, inspect.isclass)
        if not m[0].startswith("_") and
        m[1].__module__.startswith(module.__name__)
    }
