#!/usr/bin/env python3

from pathlib import Path
import html
import mistune
import re


def get_src_path():
    return str(Path(__file__).resolve().parent)


def make_changelog_dict(title):
    title_parts = title.split(" ")

    return {
        "date": title_parts[2][1:-2],
        "version": title_parts[1]
    }


def make_release_tag(version, date):
    return "    <release version=\"" + html.escape(version) \
            + "\" date=\"" + html.escape(date) \
            + "\" />\n" \


markdown_parser = mistune.Markdown(escape=False)
changelog_title_pattern = re.compile(r"##\ \d\.\d\.\d\ \(\d{4}-\d{2}-\d{2}\)")
changelog_lines = open(get_src_path() + "/docs/CHANGELOG.md", "r").readlines()
changelog_entries = []

for line in changelog_lines:
    if changelog_title_pattern.match(line):
        changelog_entry = make_changelog_dict(line)
        changelog_entries.append(changelog_entry)

appdata_releases = ""

for entry in changelog_entries:
    appdata_releases += make_release_tag(entry["version"], entry["date"])

appdata_path = get_src_path() + "/packaging/mirage.appdata.xml"
appdata_lines = open(appdata_path, "r").readlines()
releases_open_pattern = re.compile(r"  <releases>")
releases_close_pattern = re.compile(r"  </releases>")

opening_tag_found = False
releases_open_line = 0
releases_close_line = 0

for line in appdata_lines:
    if not opening_tag_found:
        releases_open_line += 1
    if releases_open_pattern.match(line):
        opening_tag_found = True
    if releases_close_pattern.match(line):
        break
    releases_close_line += 1

# We need to remove the old release entries since we're inserting
# new ones unconditionally
del appdata_lines[releases_open_line:releases_close_line]
appdata_lines.insert(releases_open_line, appdata_releases)

with open(appdata_path, "w") as appdata_file:
    appdata_lines = "".join(appdata_lines)
    appdata_file.write(appdata_lines)
