# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under LGPLv3.

import re
from typing import Generator

PROPERTY_TYPES = {"bool", "double", "int", "list", "real", "string", "url",
                  "var", "date", "point", "rect", "size", "color"}


def _add_property(line: str) -> str:
    if re.match(r"^\s*[a-zA-Z0-9_]+\s*:$", line):
        return re.sub(r"^(\s*)(\S*\s*):$",
                      r"\1readonly property QtObject \2: QtObject",
                      line)

    types = "|".join(PROPERTY_TYPES)
    if re.match(fr"^\s*({types}) [a-zA-Z\d_]+\s*:", line):
        return re.sub(r"^(\s*)(\S*)", r"\1readonly property \2", line)

    return line


def _process_lines(content: str) -> Generator[str, None, None]:
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
    lines  = [
        "import QtQuick 2.12",
        'import "utils.js" as Ut',
        "QtObject {",
        "    id: theme",
    ]
    lines += [f"    {line}" for line in _process_lines(theme_content)]
    lines += ["}"]
    return "\n".join(lines)
