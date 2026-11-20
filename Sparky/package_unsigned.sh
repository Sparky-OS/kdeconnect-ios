#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=${1:?give the build directory}
output=${2:?give an empty artifact directory}
commit=${3:?give the exact source commit}
workflow_commit=${4:?give the workflow commit}
app="$work/build/Build/Products/Release-iphoneos/KDE Connect.app"
test -d "$app"
file "$app/KDE Connect"
xcrun lipo "$app/KDE Connect" -verify_arch arm64
if signature_result="$(LC_ALL=C codesign --verify "$app" 2>&1)"; then
  echo 'The app unexpectedly contains a signature.' >&2
  exit 1
fi
if [[ "$signature_result" != "$app: code object is not signed at all"$'\nIn architecture: arm64' ]]; then
  printf 'Could not establish that the app is unsigned: %s\n' "$signature_result" >&2
  exit 1
fi
printf '%s\n' "$signature_result"
mkdir -p "$work/package/Payload" "$output"
cp -R "$app" "$work/package/Payload/"
licenses="$work/package/Payload/KDE Connect.app/Licenses"
mkdir -p "$licenses"
cp "$work/sources/openssl/LICENSE.txt" "$licenses/OpenSSL.txt"
cp "$root/License.md" "$licenses/KDE-Connect.md"
cp "$root/Packages/SwiftUI-MediaPicker/LICENSE" "$licenses/SwiftUI-MediaPicker.txt"
python3 - "$work/packages/checkouts" "$licenses" <<'PY'
from pathlib import Path
import sys, shutil
packages, destination = map(Path, sys.argv[1:])
expected = {'CocoaAsyncSocket', 'SwiftUI-Introspect', 'swift-collections'}
found = set()
for package in packages.iterdir():
    texts = [p for p in package.iterdir() if p.is_file() and p.name.upper().startswith(('LICENSE', 'LICENCE', 'COPYING'))]
    for source in texts:
        shutil.copyfile(source, destination / (package.name + '-' + source.name))
    if texts:
        found.add(package.name.lower())
if not {p.lower() for p in expected} <= found:
    sys.exit('Missing linked package licenses: ' + str(expected - found))
print('PASS: license text from each linked remote package')
PY
ditto -c -k --keepParent "$work/package/Payload" "$output/KDEConnect-unsigned.ipa"
python3 "$root/Sparky/package_manifest.py" "$output/KDEConnect-unsigned.ipa" --commit "$commit" --workflow-commit "$workflow_commit"
