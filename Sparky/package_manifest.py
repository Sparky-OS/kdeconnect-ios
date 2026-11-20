#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Validate the unsigned single-app package and emit its renewal-manifest entry."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('ipa', type=Path)
parser.add_argument('--commit', required=True)
parser.add_argument('--workflow-commit', required=True)
args = parser.parse_args()
with zipfile.ZipFile(args.ipa) as archive:
    names = archive.namelist()
    prefix = 'Payload/KDE Connect.app/'
    apps = {n.split('/')[1] for n in names if n.startswith('Payload/') and len(n.split('/')) > 2}
    if apps != {'KDE Connect.app'}:
        raise ValueError('Expected exactly one KDE Connect application')
    if any('/_CodeSignature/' in n or n.endswith('embedded.mobileprovision') or '.appex/' in n or '/Watch/' in n for n in names):
        raise ValueError('Expected an unsigned app without extensions or Watch programs')
    if any('/Frameworks/' in n or n.endswith('.dylib') for n in names):
        raise ValueError('This single-program signing recipe requires static third-party libraries')
    info = plistlib.loads(archive.read(prefix + 'Info.plist'))
    if (info['CFBundleIdentifier'], info['CFBundleExecutable'], info['MinimumOSVersion']) != ('org.sparkyos.kdeconnect', 'KDE Connect', '16.0'):
        raise ValueError('Unexpected bundle identity, executable or deployment target')
    if not archive.read(prefix + info['CFBundleExecutable']):
        raise ValueError('Missing program')
    for lang in ('en','pl','pt-BR','fr','de','es','ja','ko','zh-Hans','zh-Hant'):
        archive.read(prefix + lang + '.lproj/VirtualMonitor.strings')
digest = hashlib.sha256(args.ipa.read_bytes()).hexdigest()
entry = {'role': 'kdeconnect', 'path': args.ipa.name, 'sha256': digest, 'bundle_id': info['CFBundleIdentifier']}
args.ipa.with_name('kdeconnect-artifact.json').write_text(json.dumps({'commit': args.commit, 'workflow_commit': args.workflow_commit, 'apps': [entry]}, indent=2) + '\n')
args.ipa.with_name('SHA256SUMS').write_text(f'{digest}  {args.ipa.name}\n')
print('PASS: unsigned single KDE Connect application, ten plugin catalogs, renewal entry and SHA-256')
