#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
mode=${1:?ios or host}
source_dir=$(cd "${2:?source directory}" && pwd)
mkdir -p "${3:?build directory}"
work=$(cd "$3" && pwd)
args=()
case "$mode" in
  ios) target=ios64-xcrun; args=(-miphoneos-version-min=16.0) ;;
  host) target=linux-x86_64 ;;
  *) echo 'Expected ios or host' >&2; exit 1 ;;
esac
cd "$work"
# iOS <=17 uses the upstream RC2 PKCS12 import. no-module builds legacy into libcrypto.
perl "$source_dir/Configure" "$target" no-shared no-module no-tests no-apps no-docs \
  --prefix="$work/install" --libdir=lib "${args[@]}"
make -j4 build_sw
make install_sw
python3 - "$work/install" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
assert not any(p.suffix in ('.dylib', '.so') for p in root.rglob('*'))
for name in ('libssl.a', 'libcrypto.a'):
    assert (root / 'lib' / name).read_bytes().startswith(b'!<arch>\n')
print('PASS: static OpenSSL archives; no loadable library or provider')
PY
