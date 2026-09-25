"""Build the three onboarding background plates.

Run from `Teresa-Mobile-App/`:

    python tool/onboarding_art/generate.py

Why this exists rather than three hand-cropped files: the sources are the app's
own tab banners, which are *composites* — a photograph in the top ~45% and
baked marketing copy below it, wrapped in decorative arcs. Onboarding needs the
photograph and none of the rest, and "which pixels are the photograph" is a
decision that should be written down and re-runnable, not performed once in an
image editor and forgotten.

Each plate is a full-height phone canvas: the source photograph covering the
top band, dissolving into Teresa, Rizal navy for the lower third where the headline
and buttons sit. That is what lets one asset work at every aspect ratio — the
photo never has to stretch to fill a screen taller than it is, and the copy
always lands on a solid, legible ground.

**No copy is baked in.** Every word a citizen reads is native Flutter text.
The only text inside these plates is signage that was physically in the
photographed scene, which is scene content, not interface copy.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field

from PIL import Image

# A tall phone. Matches ~19.5:9 so `BoxFit.cover` crops almost nothing on a
# modern handset, and degrades gracefully on anything shorter.
CANVAS = (1080, 2340)

# Teresa, Rizal navy-950, the palette's darkest ink (lib/theme/app_colors.dart).
NAVY = (0x07, 0x0F, 0x24)

# How far the dissolve reaches back up into the photograph, as a fraction of
# canvas height. The band itself is per-plate: these sources are wide, and one
# shared band deep enough for a tall phone would scale a 2:1 photograph until
# only its middle third survived — which is how the first attempt cropped past
# both faces in the counter photo and kept the desk.
FADE = 0.15


@dataclass(frozen=True)
class Plate:
    out: str
    src: str
    #: Crop of the SOURCE that is genuinely photographic — no decorative arcs,
    #: no baked marketing copy. Left, top, right, bottom in source pixels.
    crop: tuple[int, int, int, int] | None = None
    #: Height of the photographic band as a fraction of the canvas.
    #:
    #: A trade, tuned per plate against its source aspect: a deeper band fills
    #: more of the screen but scales a wide photograph until only its middle
    #: survives. The first pass at 0.32 left a dead navy field roughly a fifth
    #: of the screen tall between the photograph and the copy, visible on a
    #: device and on nothing else.
    band: float = 0.44
    #: 0 = keep the top of the crop when it is taller than the band, 1 = keep
    #: the bottom. Faces and horizons are rarely in the middle.
    focus_y: float = 0.5
    focus_x: float = 0.5
    notes: str = field(default='')


PLATES = [
    Plate(
        out='page_1_bg.jpg',
        src='teresa-rizal-aerial.jpg',
        band=0.50,
        focus_y=0.58,
        notes='The coastline at sunrise. No crop needed — the only source with '
        'no composited layer at all.',
    ),
    Plate(
        out='page_2_bg.jpg',
        src='Dokyu Tab.png',
        # Below the wall sign and inside the decorative arcs: the handover
        # itself, which is the only part of the frame that says "a request was
        # served".
        # Top edge sits just BELOW the wall sign reading "Serbisyong Tapat,
        # Para sa Lahat." A first pass at y=140 kept it, which is baked
        # interface-looking copy inside a background — the thing this redesign
        # exists to remove.
        crop=(70, 248, 1000, 655),
        band=0.42,
        focus_x=0.52,
        focus_y=0.55,
        notes='Municipal services counter, document handover.',
    ),
    Plate(
        out='page_3_bg.jpg',
        src='Emergency.png',
        # Deliberately excludes the right-hand third. That region is an
        # illustrated signboard listing "EMERGENCY HOTLINE 911 / DISASTER
        # RESPONSE / MEDICAL ASSISTANCE / FIRE INCIDENT" — interface copy baked
        # into a photograph, which is the exact thing this redesign removed.
        crop=(30, 190, 700, 588),
        band=0.48,
        focus_x=0.48,
        focus_y=0.45,
        notes='Flood rescue and response. Signboard cropped out.',
    ),
]

SRC_DIR = os.path.join('assets', 'images')
OUT_DIR = os.path.join('assets', 'images', 'welcome')


def build(plate: Plate) -> str:
    img = Image.open(os.path.join(SRC_DIR, plate.src)).convert('RGB')
    if plate.crop:
        img = img.crop(plate.crop)

    width, height = CANVAS
    band = int(height * plate.band)

    # Cover the band, then take the requested focal slice rather than the
    # middle — on the counter photo the middle is a desk.
    scale = max(width / img.width, band / img.height)
    img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)
    left = int((img.width - width) * plate.focus_x)
    top = int((img.height - band) * plate.focus_y)
    img = img.crop((left, top, left + width, top + band))

    canvas = Image.new('RGB', CANVAS, NAVY)

    # Dissolve the foot of the photograph into the navy so there is no seam.
    # An alpha ramp rather than a blur: a blur still ends somewhere.
    #
    # Pasted ONCE, through the mask. The first version pasted the photo opaque
    # and then again through the mask, so the hard edge was already on the
    # canvas and the ramp had nothing to soften.
    fade_px = int(height * FADE)
    ramp = Image.new('L', (1, band), 255)
    for y in range(band):
        d = y - (band - fade_px)
        ramp.putpixel((0, y), 255 if d <= 0 else max(0, 255 - int(255 * d / fade_px)))
    mask = ramp.resize((width, band))
    canvas.paste(img, (0, 0), mask)

    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, plate.out)
    canvas.save(path, quality=80, optimize=True, progressive=True)
    return path


if __name__ == '__main__':
    for p in PLATES:
        path = build(p)
        kb = os.path.getsize(path) // 1024
        print(f'{path}  {kb} KB   <- {p.src}')
