from pathlib import Path
import json
from PIL import Image
root=Path(__file__).resolve().parents[2]
assets=root/'IOS/Resources/Assets.xcassets'
assets.mkdir(parents=True,exist_ok=True)
(assets/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
def image_set(name,source,size):
    target=assets/(name+'.imageset');target.mkdir(exist_ok=True)
    im=Image.open(source).convert('RGBA');im.thumbnail((size,size));im.save(target/'image.png',optimize=True)
    (target/'Contents.json').write_text(json.dumps({'images':[{'filename':'image.png','idiom':'universal'}],'info':{'author':'xcode','version':1}}))
image_set('hero',root/'public/images/kitchen-editorial-hero.jpg',1400)
image_set('mascot',root/'public/images/mascot-corgi.png',400)
for source in (root/'generated/kitchen_asset_pack_v2/ingredient_masters').glob('*_raw.png'):
    image_set('ingredient_'+source.stem.removesuffix('_raw'),source,240)
icon=assets/'AppIcon.appiconset';icon.mkdir(exist_ok=True)
source=root/'flutter_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
Image.open(source).convert('RGB').save(icon/'icon.png')
(icon/'Contents.json').write_text(json.dumps({'images':[{'filename':'icon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}}))
print('Exported',len(list(assets.glob('*.imageset'))),'native image sets')
