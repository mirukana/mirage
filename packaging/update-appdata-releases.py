#!/usr/bin/env python3

import html
import re
from pathlib import Path

root          = Path(__file__).resolve().parent.parent
title_pattern = re.compile(r"## (\d+\.\d+\.\d+) \((\d{4}-\d\d-\d\d)\)")
release_lines = ["  <releases>"]

for line in (root / "docs" / "CHANGELOG.md").read_text().splitlines():
    match = title_pattern.match(line)

    if match:
        args = (html.escape(match.group(1)), html.escape(match.group(2)))
        release_lines.append('    <release version="%s" date="%s"/>' % args)

appdata     = root / "packaging" / "mirage.appdata.xml"
in_releases = False
final_lines = []

for line in appdata.read_text().splitlines():
    if line == "  <releases>":
        in_releases = True
        final_lines += release_lines
    elif line == "  </releases>":
        in_releases = False

    if not in_releases:
        final_lines.append(line)

appdata.write_text("\n".join(final_lines))
