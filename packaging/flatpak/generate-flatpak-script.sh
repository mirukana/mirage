#!/usr/bin/env sh
set -e

dir="$(dirname "$(readlink -f "$0")")"
pip_generator_url='https://raw.githubusercontent.com/flatpak/flatpak-builder-tools/master/pip/flatpak-pip-generator'

cd "$dir"

python3 -m venv flatpak-env
export PATH="$dir/flatpak-env/bin:$PATH"

pip3 install -Ur requirements.flatpak.txt
pip3 install -Ur ../../requirements.txt

# Freeze requirements, ignore blacklisted packages
pip3 freeze | grep -v six= | grep -v matrix-nio > flatpak-env-requirements.txt

# Generate flatpak requirements
pip3 install requirements-parser
[ ! -f flatpak-pip-generator ] && wget "$pip_generator_url"
python3 flatpak-pip-generator -r flatpak-env-requirements.txt -o flatpak-pip

pip3 install PyYAML
python3 collector.py
