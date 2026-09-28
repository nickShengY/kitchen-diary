"""Copy selected XCTest captures as opaque, App Store-sized PNGs (requires Pillow)."""
import json, sys
from pathlib import Path
from PIL import Image
source=Path(sys.argv[1]);device=sys.argv[2]
allowed={'iphone':{(1320,2868)},'ipad':{(2064,2752),(2048,2732)},'watch':{(416,496)}}
if device not in allowed: raise SystemExit('Device must be iphone, ipad or watch')
out=Path(__file__).resolve().parents[1]/'Release/Screenshots'/device
out.mkdir(parents=True,exist_ok=True)
selected={'01-explore','02-cooking','03-pantry','04-wheel-result','Watch-crown-wheel','Watch-cooking-guide'}
for test in json.loads((source/'manifest.json').read_text()):
    for attachment in test['attachments']:
        name=attachment['suggestedHumanReadableName'].split('_0_')[0]
        if name not in selected: continue
        image=Image.open(source/attachment['exportedFileName'])
        if image.size not in allowed[device]: raise SystemExit(f'Wrong {device} dimensions: {image.size}')
        image.convert('RGB').save(out/(name+'.png'),optimize=True)
        print(device,name,image.size)
