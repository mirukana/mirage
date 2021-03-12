#!/usr/bin/env sh
set -e

here="$(dirname "$(readlink -f "$0")")"

export RESTORE_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
export RESTORE_PYTHONHOME="$PYTHONHOME"
export RESTORE_PYTHONUSERBASE="$PYTHONUSERBASE"

export SSL_CERT_FILE="$here/usr/lib/python$PY_XY/site-packages/certifi/cacert.pem"
export LD_LIBRARY_PATH="$here/usr/lib:$LD_LIBRARY_PATH"
export PYTHONHOME="$here/usr"
export PYTHONUSERBASE="$here/usr"

cd "$here"
exec "$here/usr/bin/mirage" "$@"
