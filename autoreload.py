#!/usr/bin/env python3
"""Usage: ./autoreload.py [MIRAGE_ARGUMENTS]...

Automatically rebuild and restart the application when source files change.
CONFIG+=dev will be passed to qmake, see mirage.pro.
The application will be launched with `-name dev`, which sets the first
part of the WM_CLASS as returned by xprop on Linux.

Use `pip3 install --user -U requirements-dev.txt` before running this."""

import subprocess
import sys
from pathlib import Path
from shutil import get_terminal_size

from watchgod import DefaultWatcher, run_process

SCRIPT_DIR = Path(__file__).parent


class Watcher(DefaultWatcher):
    ignored_dirs = (
        *DefaultWatcher.ignored_dirs, "build", "packaging", "config", "themes",
    )

    ignored_file_regexes = (
        *DefaultWatcher.ignored_file_regexes,
        r".*\.md$",
        r"^tags$",
        r"^COPYING(\.LESSER)?$",
        r"^requirements.*\.txt$",
        r"^Makefile$",
        r"^\.qmake\.stash$",
        r"^mirage$",
        r"^autoreload\.py$",
    )


def run_app(args=sys.argv[1:]) -> None:
    print("\n\x1b[36m", "─" * get_terminal_size().columns, "\x1b[0m\n", sep="")

    try:
        subprocess.run(("qmake", "mirage.pro", "CONFIG+=dev"), cwd=SCRIPT_DIR)
        subprocess.run("make", cwd=SCRIPT_DIR)
        p = subprocess.run(("./mirage", "-name", "dev", *args), cwd=SCRIPT_DIR)

        if p.returncode != 0:
            print(f"App exited with code {p.returncode}")
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] in ("-h", "--help"):
        print(__doc__)
    else:
        subprocess.run(("make", "clean"), cwd=SCRIPT_DIR)
        run_process(SCRIPT_DIR, run_app, watcher_cls=Watcher, callback=print)
