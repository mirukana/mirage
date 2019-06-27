PKG_DIR = src

PYTHON  = python3
PYLINT  = pylint
MYPY    = mypy
VULTURE = vulture
BANDIT  = bandit
PYCYLE  = pycycle
CLOC    = cloc

PYLINT_FLAGS    = --output-format colorized
MYPY_FLAGS      = --ignore-missing-imports
VULTURE_FLAGS   = --min-confidence 70
BANDIT_FLAGS    =
PYCYLE_FLAGS    =
CLOC_FLAGS      = --ignore-whitespace

LINE = "\033[35m―――――――――――――――――――――――――――――――――――――――――――――――――――――――\033[0m"

.PHONY: clean test

clean:
	find . -name '__pycache__' -exec rm -Rfv {} +
	find . -name '*.pyc'       -exec rm -Rfv {} +
	find . -name '*.qmlc'      -exec rm -Rfv {} +
	find . -name '*.jsc'       -exec rm -Rfv {} +
	find . -name '*.egg-info'  -exec rm -Rfv {} +

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
	- ${PYLINT} ${PYLINT_FLAGS} ${PKG_DIR}
	@echo
	@echo cloc ${LINE}
	@echo
	- ${CLOC} ${CLOC_FLAGS} ${PKG_DIR}
