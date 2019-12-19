# SPDX-License-Identifier: LGPL-3.0-or-later

"""QPL (Qt Property Language) theme files to QML converter.

QPL is a custom configuration format currently used for theme files.
This is a big hack and will be replaced in the future by a standard language.
"""

import re
from typing import Generator

PROPERTY_TYPES = {"bool", "double", "int", "list", "real", "string", "url",
                  "var", "date", "point", "rect", "size", "color"}


def _add_property(line: str) -> str:
    """Return a QML property declaration line from a QPL property line."""

    if re.match(r"^\s*[a-zA-Z\d_]+\s*:$", line):
        return re.sub(r"^(\s*)(\S*\s*):$",
                      r"\1readonly property QtObject \2: QtObject",
                      line)

    types = "|".join(PROPERTY_TYPES)
    if re.match(fr"^\s*({types}) [a-zA-Z\d_]+\s*:", line):
        return re.sub(r"^(\s*)(\S*)", r"\1property \2", line)

    return line


def _process_lines(content: str) -> Generator[str, None, None]:
    """Yield lines of real QML from lines of QPL."""

    skip           = False
    indent         = " " * 4
    current_indent = 0

    for line in content.split("\n"):
        line = line.rstrip()

        if not line.strip() or line.strip().startswith("//"):
            continue

        start_space_list = re.findall(r"^ +", line)
        start_space      = start_space_list[0] if start_space_list else ""

        line_indents = len(re.findall(indent, start_space))

        if not skip:
            if line_indents > current_indent:
                yield "%s{" % (indent * current_indent)
                current_indent = line_indents

            while line_indents < current_indent:
                current_indent -= 1
                yield "%s}" % (indent * current_indent)

            line = _add_property(line)

        yield line

        skip = any((line.endswith(e) for e in "([{+\\,?:"))

    while current_indent:
        current_indent -= 1
        yield "%s}" % (indent * current_indent)


def convert_to_qml(theme_content: str) -> str:
    """Return valid QML code with imports from QPL content."""

    lines  = [
        "import QtQuick 2.12",
        'import "../Base"',
        "QtObject {",
        "    function hsluv(h, s, l, a) { return utils.hsluv(h, s, l, a) }",
        "    function hsl(h, s, l)      { return utils.hsl(h, s, l) }",
        "    function hsla(h, s, l, a)  { return utils.hsla(h, s, l, a) }",
        "    id: theme",
    ]
    lines += [f"    {line}" for line in _process_lines(theme_content)]
    lines += ["}"]

    return "\n".join(lines)
