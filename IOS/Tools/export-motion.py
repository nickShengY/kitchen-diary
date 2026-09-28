from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[2]
out=root/'IOS/Resources/Motion';out.mkdir(exist_ok=True)
for source in (root/'generated/kitchen_asset_pack_v2/animations/actions').glob('*.webp'):
    im=Image.open(source);frames=[];durations=[]
    for i in range(im.n_frames):
        im.seek(i);frame=im.convert('RGBA');frame.thumbnail((300,300));frames.append(frame);durations.append(im.info.get('duration',80))
    frames[0].save(out/(source.stem+'.png'),save_all=True,append_images=frames[1:],duration=durations,loop=0,disposal=0,blend=0,optimize=True)
print('Exported',len(list(out.glob('*.png'))),'original action animations')
