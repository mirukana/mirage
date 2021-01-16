#!/usr/bin/env python3
"""Usage: ./autoreload.py [MIRAGE_ARGUMENTS]...

Automatically rebuild and restart the application when source files change.
CONFIG+=dev will be passed to qmake, see mirage.pro.
The application will be launched with `-name dev`, which sets the first
part of the WM_CLASS as returned by xprop on Linux.
Any other arguments will be passed to the app, see `mirage --help`.

Use `pip3 install --user -U requirements-dev.txt` before running this."""

import os
import subprocess
import sys
from contextlib import suppress
from pathlib import Path
from shutil import get_terminal_size as term_size

from watchgod import DefaultWatcher, run_process

ROOT = Path(__file__).parent


class Watcher(DefaultWatcher):
    def accept_change(self, entry: os.DirEntry) -> bool:
        path = Path(entry.path)

        for bad in ("src/config", "src/themes"):
            if path.is_relative_to(ROOT / bad):
                return False

        for good in ("src", "submodules"):
            if path.is_relative_to(ROOT / good):
                return True

        return False

    def should_watch_dir(self, entry: os.DirEntry) -> bool:
        return super().should_watch_dir(entry) and self.accept_change(entry)

    def should_watch_file(self, entry: os.DirEntry) -> bool:
        return super().should_watch_file(entry) and self.accept_change(entry)


def cmd(*parts) -> subprocess.CompletedProcess:
    return subprocess.run(parts, cwd=ROOT, check=True)


def run_app(args=sys.argv[1:]) -> None:
    print("\n\x1b[36m", "─" * term_size().columns, "\x1b[0m\n", sep="")

    with suppress(KeyboardInterrupt):
        cmd("qmake", "mirage.pro", "CONFIG+=dev")
        cmd("make")
        cmd("./mirage", "-name", "dev", *args)


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] in ("-h", "--help"):
        print(__doc__)
    else:
        (ROOT / "Makefile").exists() and cmd("make", "clean")
        run_process(ROOT, run_app, callback=print, watcher_cls=Watcher)
