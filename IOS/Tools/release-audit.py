#!/usr/bin/env python3
"""Inspect source or an unsigned/signed archive. Never treats unsigned code as shippable."""
import json, plistlib, re, struct, subprocess, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
checks=[]
def check(name, passed, detail=''):
    checks.append({'check':name,'passed':bool(passed),'detail':detail})
project=(root/'KitchenDiary.xcodeproj/project.pbxproj').read_text()
check('iPhone and iPad targeted', '"1,2"' in project)
check('Marketing/build versions present', 'MARKETING_VERSION = 1.0.0' in project and 'CURRENT_PROJECT_VERSION = 1' in project)
entitlements=plistlib.loads((root/'Resources/KitchenDiary.entitlements').read_bytes())
check('Sign in with Apple entitlement', entitlements.get('com.apple.developer.applesignin')==['Default'])
for name in ['Assets','WatchAssets']:
    icon=root/f'Resources/{name}.xcassets/AppIcon.appiconset/icon.png'
    width,height,depth,color=struct.unpack('>IIBB',icon.read_bytes()[16:26])
    check(name+' store icon', (width,height)==(1024,1024) and color==2, f'{width}x{height}; PNG color type {color} (2 = RGB)')
manifest=plistlib.loads((root/'Resources/PrivacyInfo.xcprivacy').read_bytes())
check('No tracking declared', manifest['NSPrivacyTracking'] is False)
check('UserDefaults reason declared', any(x['NSPrivacyAccessedAPIType']=='NSPrivacyAccessedAPICategoryUserDefaults' for x in manifest['NSPrivacyAccessedAPITypes']))
if len(sys.argv)>1:
    archive=Path(sys.argv[1]);app=archive/'Products/Applications/KitchenDiary.app'
    info=plistlib.loads((app/'Info.plist').read_bytes())
    check('Archive version', bool(info.get('CFBundleShortVersionString')) and bool(info.get('CFBundleVersion')))
    watch=app/'Watch/KitchenDiaryWatch.app'
    check('Watch app embedded',watch.is_dir())
    check('Phone privacy manifest embedded',(app/'PrivacyInfo.xcprivacy').is_file())
    check('Watch privacy manifest embedded',(watch/'PrivacyInfo.xcprivacy').is_file())
    check('No StoreKit test configuration in shipping app',not list(app.rglob('*.storekit')))
    check('Distribution provisioning profile present',(app/'embedded.mobileprovision').is_file())
    verification=subprocess.run(['codesign','--verify','--deep','--strict',str(app)],capture_output=True,text=True)
    check('Code signature valid',verification.returncode==0,verification.stderr.strip().replace(str(app), '<archive>/Products/Applications/KitchenDiary.app'))
identities=subprocess.run(['security','find-identity','-v','-p','codesigning'],capture_output=True,text=True).stdout
check('Apple signing identity available',bool(re.search(r'"Apple (Development|Distribution):',identities)))
print(json.dumps({'checks':checks,'readyToSubmit':False,'note':'Live auth/deletion, sandbox billing, App Store metadata, signing and Organizer validation must also be completed.'},indent=2))
sys.exit(0 if all(c['passed'] for c in checks) else 1)
