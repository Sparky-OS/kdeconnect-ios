#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output=${1:?give an empty test build directory}
mkdir -p "$output"
source_dir="$root/KDE Connect/Plugins and Plugin Views/VirtualMonitor"
if [[ $(uname -s) == Darwin ]]; then
    clang -fobjc-arc -Wall -Wextra -Werror -framework Foundation -I "$source_dir" "$source_dir/VirtualMonitorProtocol.m" "$root/Sparky/Tests/ProtocolTest.m" -o "$output/protocol-test"
else
    read -r -a flags <<< "$(gnustep-config --objc-flags)"
    read -r -a libs <<< "$(gnustep-config --base-libs)"
    clang "${flags[@]}" -I "$(gcc -print-file-name=include)" -Wall -Wextra -Werror -I "$source_dir" "$source_dir/VirtualMonitorProtocol.m" "$root/Sparky/Tests/ProtocolTest.m" "${libs[@]}" -o "$output/protocol-test"
fi
"$output/protocol-test"
python3 "$root/Sparky/check_catalogs.py"
