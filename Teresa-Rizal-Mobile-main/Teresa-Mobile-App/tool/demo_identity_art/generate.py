"""Generate the demo identities' profile avatars and government-ID card images.

    python tool/demo_identity_art/generate.py        # from Teresa-Mobile-App/

FE 02 retired three real residents' photographs and ID scans from this app. What
replaced them is generated here, so the artwork can be regenerated, reviewed and
argued with — the previous images could only be trusted.

Two deliberate choices:

* **No synthetic faces.** A generated portrait is either derived from real people
  or it is uncanny, and neither belongs in a municipal app's demo data. The
  avatars are initials on the app's navy. A placeholder that looks like a
  placeholder is more honest than a plausible stranger.

* **The ID cards are unmistakably not IDs.** Full-width diagonal watermark, an
  explicit "SPECIMEN" band, and a photo box that carries initials rather than a
  face. The originals already bore a demo watermark; this keeps that and goes
  further, because these render inside a screen whose whole purpose is to look
  like a real submitted document.

Every value printed here is invented. See the retired-identity record kept
outside this public repository.
"""
import os

from PIL import Image, ImageDraw, ImageFont

OUT = 'assets/images'

# Matches lib/theme/app_colors.dart
NAVY_900 = (11, 23, 48)
NAVY_700 = (26, 44, 82)
BRAND_600 = (29, 71, 214)
SLATE_100 = (241, 245, 249)
SLATE_400 = (148, 163, 184)
SLATE_600 = (71, 85, 105)
WHITE = (255, 255, 255)

FONT_DIR = os.environ.get('WINDIR', 'C:/Windows') + '/Fonts'
_APP_FONTS = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'fonts')


def font(bold, size):
    """Prefer bundled Inter, then Arial, so this runs on Linux, macOS and Windows."""
    for path in (
        os.path.join(_APP_FONTS, 'Inter.ttf'),
        os.path.join(FONT_DIR, 'arialbd.ttf' if bold else 'arial.ttf'),
        '/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf',
        '/Library/Fonts/Arial Bold.ttf' if bold else '/Library/Fonts/Arial.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    ):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def initials(full_name):
    parts = [p for p in full_name.split() if p]
    return (parts[0][0] + parts[-1][0]).upper() if len(parts) > 1 else parts[0][:2].upper()


def centre(draw, box, text, fnt, fill):
    x0, y0, x1, y1 = box
    l, t, r, b = draw.textbbox((0, 0), text, font=fnt)
    draw.text((x0 + (x1 - x0 - (r - l)) / 2 - l, y0 + (y1 - y0 - (b - t)) / 2 - t), text, font=fnt, fill=fill)


def avatar(name, path, size=1254):
    """Initials on navy. Deliberately not a face."""
    img = Image.new('RGB', (size, size), NAVY_900)
    d = ImageDraw.Draw(img)
    d.ellipse([size * 0.14, size * 0.14, size * 0.86, size * 0.86], fill=NAVY_700)
    centre(d, (0, 0, size, size), initials(name), font(True, int(size * 0.30)), WHITE)
    label = 'DEMO PROFILE'
    f = font(True, int(size * 0.042))
    centre(d, (0, int(size * 0.86), size, int(size * 0.95)), label, f, SLATE_400)
    img.save(path)
    print('  %-34s %s' % (os.path.basename(path), img.size))


def id_card(name, id_type, id_number, birthdate, address, path, size=(1578, 997)):
    w, h = size
    img = Image.new('RGB', size, SLATE_100)
    d = ImageDraw.Draw(img)

    # Header band
    d.rectangle([0, 0, w, int(h * 0.17)], fill=NAVY_900)
    d.text((int(w * 0.035), int(h * 0.045)), 'REPUBLIC OF THE PHILIPPINES', font=font(True, int(h * 0.038)), fill=SLATE_400)
    d.text((int(w * 0.035), int(h * 0.088)), id_type.upper(), font=font(True, int(h * 0.055)), fill=WHITE)

    # Photo box — initials, never a face
    bx0, by0 = int(w * 0.035), int(h * 0.24)
    bx1, by1 = bx0 + int(w * 0.20), by0 + int(h * 0.52)
    d.rectangle([bx0, by0, bx1, by1], fill=NAVY_700)
    centre(d, (bx0, by0, bx1, by1), initials(name), font(True, int(h * 0.20)), WHITE)
    centre(d, (bx0, by1 + 6, bx1, by1 + int(h * 0.08)), 'NO PHOTO — DEMO', font(True, int(h * 0.028)), SLATE_600)

    # Fields
    fx = bx1 + int(w * 0.045)
    y = by0
    for label, value in (
        ('NAME', name.upper()),
        ('ID NUMBER', id_number),
        ('DATE OF BIRTH', birthdate),
        ('ADDRESS', address),
    ):
        d.text((fx, y), label, font=font(True, int(h * 0.030)), fill=SLATE_600)
        d.text((fx, y + int(h * 0.038)), value, font=font(True, int(h * 0.050)), fill=NAVY_900)
        y += int(h * 0.125)

    # Unmistakable specimen marking
    d.rectangle([0, int(h * 0.86), w, h], fill=BRAND_600)
    centre(d, (0, int(h * 0.86), w, h), 'SPECIMEN — DEMONSTRATION DATA — NOT A VALID GOVERNMENT ID', font(True, int(h * 0.042)), WHITE)

    mark = Image.new('RGBA', (w * 2, h * 2), (0, 0, 0, 0))
    md = ImageDraw.Draw(mark)
    md.text((int(w * 0.10), int(h * 0.75)), 'DEMO ONLY', font=font(True, int(h * 0.42)), fill=(220, 38, 38, 70))
    img.paste(Image.alpha_composite(img.convert('RGBA'), mark.rotate(20, center=(0, 0)).crop((0, 0, w, h))).convert('RGB'))

    img.save(path)
    print('  %-34s %s' % (os.path.basename(path), img.size))


IDENTITIES = [
    # (name, avatar file, id file, id type, id number, birthdate, address, id size)
    ('Perlita Quiambao', 'Perlita Profile.png', 'PERLITA DEMO ID.png',
     'Postal ID (PHLPost)', 'PRN 100141234567 P', 'February 4, 2001',
     'Purok 2, Brgy. Baras, Teresa, Rizal', (1578, 997)),
    ('Nicanor Sarmiento', 'Nicanor Sarmiento.png', 'NICANOR ID DEMO.png',
     'Teresa, Rizal Resident ID', 'ESP-RES-2024-9001', 'June 8, 1990',
     'Purok 2, Brgy. Labangtaytay, Teresa, Rizal', (1578, 997)),
    ('Anacleto Dimaculangan', 'Anacleto Dimaculangan.png', 'ANACLETO ID DEMO.png',
     'Teresa, Rizal Resident ID', 'ESP-RES-2024-9013', 'October 27, 1992',
     'Purok 3, Brgy. Libertad, Teresa, Rizal', (1573, 1000)),
]


def wallet_card(title, subtitle, name, id_number, fields, path, size, back=False):
    """A Digital ID wallet card — front carries the holder, back the notes.

    These four were missed in FE 02's first pass and found by running the app on
    a device: the wallet still rendered a real resident's photograph, name,
    birthdate, address and mobile number. The text layer had been renamed, so
    the screen showed the synthetic name in its metadata while the card image
    below it showed the real one. A text-only ban test cannot see a name that
    lives in pixels.
    """
    w, h = size
    img = Image.new('RGB', size, WHITE)
    d = ImageDraw.Draw(img)

    d.rectangle([0, 0, w, int(h * 0.15)], fill=NAVY_900)
    d.text((int(w * 0.03), int(h * 0.030)), 'MUNICIPALITY OF TERESA, RIZAL', font=font(True, int(h * 0.036)), fill=SLATE_400)
    d.text((int(w * 0.03), int(h * 0.072)), title, font=font(True, int(h * 0.052)), fill=WHITE)
    d.text((w - int(w * 0.03) - d.textlength(subtitle, font=font(True, int(h * 0.034))), int(h * 0.085)),
           subtitle, font=font(True, int(h * 0.034)), fill=SLATE_400)

    if not back:
        bx0, by0 = int(w * 0.035), int(h * 0.22)
        bx1, by1 = bx0 + int(w * 0.19), by0 + int(h * 0.50)
        d.rectangle([bx0, by0, bx1, by1], fill=NAVY_700)
        centre(d, (bx0, by0, bx1, by1), initials(name), font(True, int(h * 0.19)), WHITE)
        centre(d, (bx0, by1 + 4, bx1, by1 + int(h * 0.075)), 'NO PHOTO — DEMO', font(True, int(h * 0.026)), SLATE_600)
        fx, y = bx1 + int(w * 0.04), by0
        for label, value in fields:
            d.text((fx, y), label, font=font(True, int(h * 0.026)), fill=SLATE_600)
            d.text((fx, y + int(h * 0.032)), value, font=font(True, int(h * 0.044)), fill=NAVY_900)
            y += int(h * 0.098)
        d.text((int(w * 0.68), int(h * 0.22)), 'ID NUMBER', font=font(True, int(h * 0.026)), fill=SLATE_600)
        d.text((int(w * 0.68), int(h * 0.255)), id_number, font=font(True, int(h * 0.040)), fill=NAVY_900)
    else:
        y = int(h * 0.26)
        for label, value in fields:
            d.text((int(w * 0.05), y), label, font=font(True, int(h * 0.028)), fill=SLATE_600)
            d.text((int(w * 0.05), y + int(h * 0.034)), value, font=font(True, int(h * 0.042)), fill=NAVY_900)
            y += int(h * 0.105)

    d.rectangle([0, int(h * 0.86), w, h], fill=BRAND_600)
    centre(d, (0, int(h * 0.86), w, h), 'SPECIMEN — DEMONSTRATION DATA — NOT A VALID GOVERNMENT ID',
           font(True, int(h * 0.040)), WHITE)

    mark = Image.new('RGBA', (w * 2, h * 2), (0, 0, 0, 0))
    ImageDraw.Draw(mark).text((int(w * 0.12), int(h * 0.75)), 'DEMO ONLY',
                              font=font(True, int(h * 0.40)), fill=(220, 38, 38, 65))
    img.paste(Image.alpha_composite(img.convert('RGBA'), mark.rotate(20, center=(0, 0)).crop((0, 0, w, h))).convert('RGB'))
    img.save(path)
    print('  %-34s %s' % (os.path.basename(path), img.size))


WALLET = [
    ('Barangay Resident ID', 'BRGY. BARAS', 'Perlita Quiambao', 'ESP-RES-2024-9002',
     [('FULL NAME', 'PERLITA QUIAMBAO'), ('DATE OF BIRTH', 'February 4, 2001'),
      ('ADDRESS', 'Purok 2, Brgy. Baras')],
     'BarangayID_Front.png', (1573, 1000), False),
    ('Barangay Resident ID', 'REVERSE', 'Perlita Quiambao', 'ESP-RES-2024-9002',
     [('ISSUED BY', 'Municipality of Teresa, Rizal'), ('VALIDITY', 'No expiry — demonstration card'),
      ('NOTE', 'Every value on this card is invented.')],
     'BarangayID_Back.png', (1578, 997), True),
    ('PWD Identification Card', 'MSWDO', 'Perlita Quiambao', 'ESP-PWD-2024-9002',
     [('FULL NAME', 'PERLITA QUIAMBAO'), ('DATE OF BIRTH', 'February 4, 2001'),
      ('ADDRESS', 'Purok 2, Brgy. Baras')],
     'PWD_Front.png', (1577, 997), False),
    ('PWD Identification Card', 'REVERSE', 'Perlita Quiambao', 'ESP-PWD-2024-9002',
     [('ISSUED BY', 'Municipal Social Welfare and Development Office'),
      ('VALIDITY', 'No expiry — demonstration card'),
      ('NOTE', 'Every value on this card is invented.')],
     'PWD_Back.png', (1578, 996), True),
]


def main():
    if not os.path.isdir(OUT):
        raise SystemExit('run this from Teresa-Mobile-App/ — %s not found' % OUT)
    print('Generating demo identity art into %s/' % OUT)
    for name, av, idf, id_type, id_no, dob, addr, id_size in IDENTITIES:
        avatar(name, os.path.join(OUT, av))
        id_card(name, id_type, id_no, dob, addr, os.path.join(OUT, idf), id_size)
    for title, subtitle, name, id_no, fields, fn, size, back in WALLET:
        wallet_card(title, subtitle, name, id_no, fields, os.path.join(OUT, fn), size, back)
    print('done — every value above is invented; see the retired-identity record kept outside this repo')


if __name__ == '__main__':
    main()
