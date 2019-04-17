# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

PKG_DIR = harmonyqml

PYTHON = python3
PIP    = pip3
PYLINT = pylint
CLOC   = cloc

ARCHIVE_FORMATS = gztar
INSTALL_FLAGS   = --user --editable
PYLINT_FLAGS    = --output-format colorized
CLOC_FLAGS      = --ignore-whitespace

.PHONY: all clean dist install upload test


all: clean dist install

clean:
	find . -name '__pycache__' -exec rm -Rfv {} +
	find . -name '*.pyc'       -exec rm -Rfv {} +
	find . -name '*.qmlc'      -exec rm -Rfv {} +
	find . -name '*.jsc'       -exec rm -Rfv {} +
	find . -name '*.egg-info'  -exec rm -Rfv {} +
	rm -Rfv build dist

dist: clean
	@echo
	${PYTHON} setup.py sdist --format ${ARCHIVE_FORMATS}
	@echo
	${PYTHON} setup.py bdist_wheel

install: clean
	@echo
	${PIP} install ${INSTALL_FLAGS} .


upload: dist
	@echo
	twine upload dist/*


test:
	- ${PYLINT} ${PYLINT_FLAGS} ${PKG_DIR} *.py
	@echo
	${CLOC} ${CLOC_FLAGS} ${PKG_DIR}
