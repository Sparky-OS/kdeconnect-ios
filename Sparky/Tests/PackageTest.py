#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import zipfile

script = Path(__file__).resolve().parents[1] / 'package_manifest.py'
prefix = 'Payload/KDE Connect.app/'
info = {'CFBundleIdentifier':'org.sparkyos.kdeconnect', 'CFBundleExecutable':'KDE Connect', 'MinimumOSVersion':'16.0'}
base = {prefix+'Info.plist':plistlib.dumps(info), prefix+'KDE Connect':b'test-only-not-a-program'}
for lang in ('en','pl','pt-BR','fr','de','es','ja','ko','zh-Hans','zh-Hant'):
    base[prefix+lang+'.lproj/VirtualMonitor.strings'] = b'fixture'
with tempfile.TemporaryDirectory() as tmp:
    ipa = Path(tmp)/'KDEConnect-unsigned.ipa'
    cases = [({}, None, True)]
    for forbidden in ('Frameworks/a.framework/a','evil.dylib','PlugIns/a.appex/a','Watch/watch.app/watch','_CodeSignature/CodeResources','embedded.mobileprovision'):
        cases.append(({prefix+forbidden:b'fixture'}, None, False))
    cases += [({'Payload/Other.app/Info.plist':b'fixture'},None,False), ({},prefix+'es.lproj/VirtualMonitor.strings',False), ({prefix+'Info.plist':plistlib.dumps(dict(info,CFBundleIdentifier='wrong'))},None,False)]
    for additions,removed,expected in cases:
        files = dict(base,**additions)
        if removed: del files[removed]
        with zipfile.ZipFile(ipa,'w') as archive:
            for name,data in files.items(): archive.writestr(name,data)
        result = subprocess.run([sys.executable,str(script),str(ipa),'--commit','a'*40,'--workflow-commit','b'*40],capture_output=True)
        assert (result.returncode==0)==expected,(additions,removed,result.stderr)
        if expected:
            manifest=json.loads(ipa.with_name('kdeconnect-artifact.json').read_text())
            assert manifest['apps'][0]['role']=='kdeconnect'
            assert manifest['apps'][0]['sha256']==hashlib.sha256(ipa.read_bytes()).hexdigest()
            assert manifest['commit']=='a'*40 and manifest['workflow_commit']=='b'*40
print('PASS: package/manifest fixtures, extra app, signature, profile, framework, dylib, extension, Watch, missing locale and wrong identity refused')
