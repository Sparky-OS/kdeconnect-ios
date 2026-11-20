#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
import hashlib
import json
from pathlib import Path
import sys
import tarfile
import urllib.request

root = Path(sys.argv[1])
root.mkdir(parents=True, exist_ok=False)
lock = json.loads(Path(__file__).with_name('openssl-source.json').read_text())
archive = root / 'openssl.tar.gz'
with urllib.request.urlopen(lock['url'], timeout=120) as response:
    archive.write_bytes(response.read())
if hashlib.sha256(archive.read_bytes()).hexdigest() != lock['sha256']:
    raise SystemExit('OpenSSL source checksum mismatch')
with tarfile.open(archive) as source:
    source.extractall(root, filter='data')
(root / lock['revision']).rename(root / 'openssl')
archive.unlink()
print('PASS: OpenSSL source checksum and safe extraction')
