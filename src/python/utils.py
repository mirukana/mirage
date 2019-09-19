import collections
import html
import xml.etree.cElementTree as xml_etree  # FIXME: bandit warning
from enum import Enum
from enum import auto as autostr
from typing import IO, Optional

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


def is_svg(file: IO) -> bool:
    try:
        _, element = next(xml_etree.iterparse(file, ("start",)))
        return element.tag == "{http://www.w3.org/2000/svg}svg"
    except (StopIteration, xml_etree.ParseError):
        return False


def guess_mime(file: IO) -> Optional[str]:
    if is_svg(file):
        return "image/svg+xml"

    file.seek(0, 0)
    return filetype.guess_mime(file)


def plain2html(text: str) -> str:
    return html.escape(text)\
               .replace("\n", "<br>")\
               .replace("\t", "&nbsp;" * 4)
