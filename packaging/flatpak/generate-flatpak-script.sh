#!/usr/bin/env bash

set -e

DIR="$(dirname "$(readlink -f "$0")")"

cd "$DIR"

python3 -m venv flatpak-env
export PATH="$DIR/flatpak-env/bin:$PATH"

if [ ! -f flatpak-pip-generator ]; then
    wget https://raw.githubusercontent.com/flatpak/flatpak-builder-tools/master/pip/flatpak-pip-generator
fi

cat requirements.flatpak.txt ../../requirements.txt > requirements.txt

flatpak-env/bin/pip install -Ur requirements.txt

# freeze requirements and ignore blacklisted packages
flatpak-env/bin/pip freeze | grep -v PyYAML | grep -v six= | grep -v matrix-nio > flatpak-requirements.txt

# generate flatpak requirements
flatpak-env/bin/python flatpak-pip-generator --output flatpak-pip \
                       --requirements-file=flatpak-requirements.txt

flatpak-env/bin/pip install PyYAML
python collector.py
