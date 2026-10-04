from PIL import Image, ImageChops, ImageDraw

src = Image.open('docs/branding/mascote-d1@2x.png').convert('RGB')
bg = src.getpixel((5, 5))
print('size', src.size, 'sheet bg', bg)


def tile_bbox(x0, x1):
    # tile = pixels that differ from the sheet background, inside a column band
    band = src.crop((x0, 0, x1, src.size[1]))
    diff = ImageChops.difference(band, Image.new('RGB', band.size, bg)).convert('L')
    box = diff.point(lambda v: 255 if v > 6 else 0).getbbox()
    return (x0 + box[0], box[1], x0 + box[2], box[3])


def cut(box, name):
    t = src.crop(box)
    side = min(t.size)
    t = t.crop((0, 0, side, side)).convert('RGBA')
    colour = t.getpixel((side // 2, 12))[:3]
    # corners outside the rounded tile -> transparent
    for xy in [(0, 0), (side - 1, 0), (0, side - 1), (side - 1, side - 1)]:
        ImageDraw.floodfill(t, xy, (0, 0, 0, 0), thresh=40)
    t.resize((1024, 1024), Image.LANCZOS).save(f'assets/branding/{name}.png')
    print(name, box, 'tile colour', colour)
    return t, colour


light, _ = cut(tile_bbox(60, 1300), 'mascot_light')
dark, dark_rgb = cut(tile_bbox(1340, 2540), 'mascot_dark')

# Launcher icon sources: full-bleed square (legacy) and padded foreground (adaptive)
side = dark.size[0]
full = Image.new('RGBA', dark.size, dark_rgb + (255,))
full.alpha_composite(dark)
full.convert('RGB').resize((1024, 1024), Image.LANCZOS).save('assets/branding/launcher_icon.png')
pad = int(side * 1.5)
fg = Image.new('RGBA', (pad, pad), dark_rgb + (255,))
fg.alpha_composite(full, ((pad - side) // 2, (pad - side) // 2))
fg.convert('RGB').resize((1024, 1024), Image.LANCZOS).save('assets/branding/launcher_icon_foreground.png')
print('dark hex #%02X%02X%02X' % dark_rgb)
