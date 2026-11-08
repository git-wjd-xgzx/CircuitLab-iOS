#!/usr/bin/env python3
"""Generate the app icon and launch images for CircuitLab.

Runs at 4x then downsamples with Lanczos for clean edges on the 57 px
icon and on Retina launch screens.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Resources")
FONT_BD = r"C:\Windows\Fonts\msyhbd.ttc"
FONT_RG = r"C:\Windows\Fonts\msyh.ttc"


def font(size, bold=True):
    return ImageFont.truetype(FONT_BD if bold else FONT_RG, size)


def vgradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / float(max(1, h - 1))
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    return img


def rounded_rect(draw, box, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_dial(draw, cx, cy, r, unit, needle_deg=302, ink=(48, 39, 24)):
    cx, cy, r = int(cx), int(cy), int(r)
    # cream face
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(244, 233, 209), outline=(112, 91, 50), width=max(2, r // 35))
    # arc
    start, end = 200, 340
    bbox = (cx - r * 0.84, cy - r * 0.84, cx + r * 0.84, cy + r * 0.84)
    draw.arc(bbox, start=start, end=end, fill=ink, width=max(2, r // 60))
    # ticks
    for i in range(31):
        a = math.radians(start + (end - start) * i / 30.0)
        major = i % 10 == 0
        r1 = r * (0.70 if major else 0.76)
        r2 = r * 0.84
        draw.line(
            (cx + math.cos(a) * r1, cy + math.sin(a) * r1,
             cx + math.cos(a) * r2, cy + math.sin(a) * r2),
            fill=ink if major else (98, 85, 57), width=max(2, r // (30 if major else 55)))
    # labels
    for i, label in enumerate(("0", "1", "2", "3")):
        a = math.radians(start + (end - start) * i / 3.0)
        lx = cx + math.cos(a) * r * 0.57
        ly = cy + math.sin(a) * r * 0.57
        f = font(max(12, int(r * 0.15)))
        tw = draw.textbbox((0, 0), label, font=f)[2]
        draw.text((lx - tw / 2, ly - r * 0.09), label, font=f, fill=ink)
    # unit
    f = font(max(18, int(r * 0.28)))
    tw = draw.textbbox((0, 0), unit, font=f)[2]
    draw.text((cx - tw / 2, cy - r * 0.28), unit, font=f, fill=ink)
    # needle
    a = math.radians(needle_deg)
    draw.line((cx, cy, cx + math.cos(a) * r * 0.74, cy + math.sin(a) * r * 0.74),
              fill=(195, 55, 34), width=max(3, r // 24))
    draw.ellipse((cx - r * 0.06, cy - r * 0.06, cx + r * 0.06, cy + r * 0.06), fill=(43, 40, 34))
    # highlight
    draw.arc((cx - r * 0.90, cy - r * 0.93, cx + r * 0.55, cy + r * 0.28),
             start=190, end=250, fill=(255, 255, 255), width=max(2, r // 45))


def make_icon(px=1024):
    img = vgradient((px, px), (28, 52, 56), (7, 19, 21)).convert("RGBA")
    d = ImageDraw.Draw(img)
    s = px / 1024.0

    # inner panel and gold hairlines
    rounded_rect(d, (26 * s, 26 * s, 998 * s, 998 * s), 210 * s,
                 outline=(196, 158, 92), width=max(2, int(5 * s)))
    rounded_rect(d, (55 * s, 55 * s, 969 * s, 969 * s), 190 * s,
                 outline=(77, 105, 103), width=max(1, int(2 * s)))

    # warm glow behind the instrument
    glow = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((115 * s, 110 * s, 909 * s, 904 * s), fill=(224, 190, 118, 42))
    glow = glow.filter(ImageFilter.GaussianBlur(int(46 * s)))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)

    # drop shadow for the round instrument
    shadow = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((190 * s, 196 * s, 858 * s, 872 * s), fill=(0, 0, 0, 135))
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(24 * s)))
    img.alpha_composite(shadow)
    d = ImageDraw.Draw(img)

    # round analogue meter
    face = (152 * s, 152 * s, 872 * s, 872 * s)
    d.ellipse(face, fill=(31, 35, 37), outline=(136, 144, 144), width=max(2, int(5 * s)))
    inner = (171 * s, 171 * s, 853 * s, 853 * s)
    d.ellipse(inner, fill=(244, 233, 209), outline=(93, 74, 39), width=max(2, int(3 * s)))
    draw_dial(d, 512 * s, 512 * s, 322 * s, "A·V", 300)

    return img


def make_launch(w, h):
    scale = 2 if w >= 640 else 1
    W, H = w * 2, h * 2
    img = vgradient((W, H), (30, 53, 57), (7, 15, 17)).convert("RGBA")
    d = ImageDraw.Draw(img)
    # faint radial halo
    halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.ellipse((W * 0.12, H * 0.20, W * 0.88, H * 0.78), fill=(197, 164, 98, 28))
    halo = halo.filter(ImageFilter.GaussianBlur(70 * scale))
    img.alpha_composite(halo)
    d = ImageDraw.Draw(img)

    # emblem disc
    cx, cy, r = W * 0.5, H * 0.38, W * 0.22
    d.ellipse((cx - r - 4 * scale, cy - r - 4 * scale, cx + r + 4 * scale, cy + r + 4 * scale),
              outline=(201, 164, 96), width=3 * scale)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(24, 40, 43), outline=(101, 128, 123), width=2 * scale)
    # gauge arc + needle
    rr = r * 0.74
    d.arc((cx - rr, cy - rr * 0.86, cx + rr, cy + rr * 1.12), start=200, end=340,
          fill=(230, 210, 166), width=3 * scale)
    for i in range(11):
        a = math.radians(200 + 140 * i / 10.0)
        d.line((cx + math.cos(a) * rr * 0.82, cy + math.sin(a) * rr * 0.82,
                cx + math.cos(a) * rr, cy + math.sin(a) * rr),
               fill=(213, 190, 144), width=(3 if i % 5 == 0 else 1) * scale)
    a = math.radians(304)
    d.line((cx, cy + r * 0.12, cx + math.cos(a) * rr * 0.82, cy + math.sin(a) * rr * 0.82),
           fill=(213, 75, 48), width=3 * scale)
    d.ellipse((cx - 4 * scale, cy + r * 0.12 - 4 * scale, cx + 4 * scale, cy + r * 0.12 + 4 * scale),
              fill=(232, 211, 168))
    f = font(int(58 * scale), True)
    tw = d.textbbox((0, 0), "电", font=f)[2]
    d.text((cx - tw / 2, cy - r * 0.38), "电", font=f, fill=(240, 225, 195))

    # title
    f = font(int(31 * scale), True)
    title = "电学实验室"
    tw = d.textbbox((0, 0), title, font=f)[2]
    d.text(((W - tw) / 2, H * 0.55), title, font=f, fill=(244, 232, 208))
    f = font(int(12 * scale), False)
    sub = "模拟电流表  ·  模拟电压表"
    tw = d.textbbox((0, 0), sub, font=f)[2]
    d.text(((W - tw) / 2, H * 0.615), sub, font=f, fill=(157, 180, 170))

    # bottom rule
    d.line((W * 0.34, H * 0.68, W * 0.66, H * 0.68), fill=(126, 101, 55), width=1 * scale)
    f = font(int(11 * scale), False)
    foot = "把用电器插入识别座，开始测量"
    tw = d.textbbox((0, 0), foot, font=f)[2]
    d.text(((W - tw) / 2, H * 0.71), foot, font=f, fill=(132, 153, 147))
    f = font(int(9 * scale), False)
    ver = "iOS 4.3+"
    tw = d.textbbox((0, 0), ver, font=f)[2]
    d.text(((W - tw) / 2, H * 0.93), ver, font=f, fill=(96, 117, 113))
    return img


def save(img, name, size):
    img = img.resize(size, Image.LANCZOS)
    if img.mode != "RGB":
        img = img.convert("RGB")
    path = os.path.join(OUT, name)
    img.save(path, "PNG", optimize=True)
    print("wrote", path, img.size)


def main():
    os.makedirs(OUT, exist_ok=True)
    icon = make_icon(1024)
    save(icon, "Icon.png", (57, 57))
    save(icon, "Icon@2x.png", (114, 114))
    save(icon, "Icon-Small.png", (29, 29))
    save(icon, "Icon-Small@2x.png", (58, 58))
    save(icon, "iTunesArtwork", (512, 512))
    save(icon, "AppIcon-512.png", (512, 512))

    save(make_launch(320, 480), "Default.png", (320, 480))
    save(make_launch(640, 960), "Default@2x.png", (640, 960))


if __name__ == "__main__":
    main()

