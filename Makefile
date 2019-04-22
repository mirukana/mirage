# Copyright 2019 miruka
# This file is part of harmonyqml, licensed under GPLv3.

PKG_DIR = harmonyqml

PYTHON  = python3
PIP     = pip3
PYLINT  = pylint
MYPY    = mypy
VULTURE = vulture
BANDIT  = bandit
PYCYLE  = pycycle
CLOC    = cloc

ARCHIVE_FORMATS = gztar
INSTALL_FLAGS   = --user --editable
PYLINT_FLAGS    = --output-format colorized
MYPY_FLAGS      = --ignore-missing-imports
VULTURE_FLAGS   = --min-confidence 70
BANDIT_FLAGS    =
PYCYLE_FLAGS    =
CLOC_FLAGS      = --ignore-whitespace

LINE = "\033[35m―――――――――――――――――――――――――――――――――――――――――――――――――――――――\033[0m"


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
	@echo
	@echo pycycle ${LINE}
	@echo
	- ${PYCYLE} --source ${PKG_DIR} ${PYCYLE_FLAGS}
	@echo
	@echo mypy ${LINE}
	@echo
	- ${MYPY} ${PKG_DIR} ${MYPY_FLAGS}
	@echo
	@echo vulture ${LINE}
	@echo
	- ${VULTURE} ${PKG_DIR} ${VULTURE_FLAGS}
	@echo
	@echo bandit ${LINE}
	@echo
	- ${BANDIT} ${PKG_DIR} --recursive ${BANDIT_FLAGS}
	@echo
	@echo pylint ${LINE}
	@echo
	- ${PYLINT} ${PYLINT_FLAGS} ${PKG_DIR} *.py
	@echo
	@echo cloc ${LINE}
	@echo
	- ${CLOC} ${CLOC_FLAGS} ${PKG_DIR}
