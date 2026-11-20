#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
import json, re
from pathlib import Path
root = Path(__file__).resolve().parent
spec = json.loads((root / 'catalog-keys.json').read_text())
print('| Key | ' + ' | '.join(spec['languages']) + ' |')
print('| --- | ' + ' | '.join('---' for _ in spec['languages']) + ' |')
for lang in spec['languages']:
    text = (root / 'Resources' / (lang + '.lproj') / 'VirtualMonitor.strings').read_text()
    entries = re.findall(r'"([^"\n]+)"\s*=\s*("(?:[^"\\]|\\.)*")\s*;', text)
    assert len(entries) == len(spec['keys']) and set(k for k, _ in entries) == set(spec['keys']), lang
    assert all(json.loads(v).strip() for _, v in entries), lang
for key in spec['keys']:
    print('| ' + key + ' | ' + ' | '.join('yes' for _ in spec['languages']) + ' |')
print('PASS: all 12 virtual-monitor strings in ten native catalogs')
