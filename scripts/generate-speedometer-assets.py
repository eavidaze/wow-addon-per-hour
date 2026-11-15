"""Generate the gauge's transparent TGA textures and a local PNG preview.

Development dependencies: Pillow and Lupa (Lua 5.1). Run from anywhere with Python 3.
"""

from math import cos, floor, pi, sin
from pathlib import Path

from lupa.lua51 import LuaRuntime
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
TEXTURES = ROOT / "src" / "textures"
OUTPUT = ROOT / "dist"
SIZE = 256
TEXTURE_SIZE = 512
SUPERSAMPLE = 8
RADIUS = 78
NEEDLE_BASE_WIDTH = 5
NEEDLE_TIP_WIDTH = 2
WHITE = (255, 255, 255, 255)


def load_theme_palette():
    # Execute the actual theme so aliases and future Lua expressions work as in the addon.
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute("PerHour = {}")
    lua.execute((ROOT / "src" / "core" / "Theme.lua").read_text(encoding="utf-8"))
    theme = lua.globals().PerHour.Theme

    def rgba(color):
        channels = [color[index] for index in range(1, len(color) + 1)]
        if len(channels) == 3:
            channels.append(1)
        return tuple(floor(channel * 255 + 0.5) for channel in channels)

    return {
        "dial": rgba(theme.gold.text),
        "needle": rgba(theme.speedometer.needle),
        "shadow": rgba(theme.speedometer.shadow),
        "text": rgba(theme.text),
    }


def position(fraction, radius):
    angle = pi * (1 - fraction)
    return SIZE / 2 + cos(angle) * radius, SIZE / 2 - sin(angle) * radius


def scaled(point):
    return tuple(round(value * SUPERSAMPLE) for value in point)


def canvas():
    return Image.new("RGBA", (SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE))


def finish(image, name):
    image = image.resize((TEXTURE_SIZE, TEXTURE_SIZE), Image.Resampling.LANCZOS)
    # Keep transparent texels white as well, avoiding dark fringes under linear sampling.
    alpha = image.getchannel("A")
    image = Image.new("RGBA", image.size, WHITE)
    image.putalpha(alpha)
    image.save(TEXTURES / name)
    return image


def make_dial():
    image = canvas()
    draw = ImageDraw.Draw(image)
    bounds = ((SIZE / 2 - RADIUS) * SUPERSAMPLE, (SIZE / 2 - RADIUS) * SUPERSAMPLE,
              (SIZE / 2 + RADIUS) * SUPERSAMPLE, (SIZE / 2 + RADIUS) * SUPERSAMPLE)
    draw.arc(bounds, 180, 360, fill=WHITE, width=2 * SUPERSAMPLE)
    for index in range(21):
        major = index % 5 == 0
        draw.line((scaled(position(index / 20, RADIUS)),
                   scaled(position(index / 20, RADIUS - (10 if major else 5)))),
                  fill=WHITE, width=(2 if major else 1) * SUPERSAMPLE)
    center, radius = SIZE * SUPERSAMPLE / 2, 3.5 * SUPERSAMPLE
    draw.ellipse((center - radius, center - radius, center + radius, center + radius), fill=WHITE)
    return finish(image, "SpeedometerDial.tga")


def make_needle():
    image = canvas()
    draw = ImageDraw.Draw(image)
    center = SIZE / 2
    # The artwork points right; its center is the rotation pivot in both axes.
    tip = center + RADIUS - 14
    draw.polygon([
        scaled((center, center - NEEDLE_BASE_WIDTH / 2)),
        scaled((tip, center - NEEDLE_TIP_WIDTH / 2)),
        scaled((tip, center + NEEDLE_TIP_WIDTH / 2)),
        scaled((center, center + NEEDLE_BASE_WIDTH / 2)),
    ], fill=WHITE)
    return finish(image, "SpeedometerNeedle.tga")


def colored(image, color):
    result = Image.new("RGBA", image.size, color)
    alpha = image.getchannel("A")
    if color[3] != 255:
        alpha = alpha.point(lambda value: round(value * color[3] / 255))
    result.putalpha(alpha)
    return result


def font(size):
    for name in ("C:/Windows/Fonts/trebuc.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default(size=size)


def make_preview(dial, needle):
    palette = load_theme_palette()
    scale = 3
    width, height = 240 * scale, 210 * scale
    image = Image.new("RGBA", (width, height), (16, 18, 20, 255))
    # Compose the same textures, logical radius and rotation pivot used by Lua.
    center = (width // 2, 135 * scale)
    texture_size = SIZE * scale
    origin = (center[0] - texture_size // 2, center[1] - texture_size // 2)
    shadow_origin = (origin[0] + scale, origin[1] + scale)
    dial_shadow = colored(dial, palette["shadow"]).resize((texture_size, texture_size), Image.Resampling.LANCZOS)
    needle_shadow = colored(needle, palette["shadow"]).resize((texture_size, texture_size), Image.Resampling.LANCZOS)
    image.alpha_composite(dial_shadow, shadow_origin)
    image.alpha_composite(needle_shadow.rotate(90, Image.Resampling.BICUBIC), shadow_origin)
    needle = colored(needle, palette["needle"]).resize((texture_size, texture_size), Image.Resampling.LANCZOS)
    needle = needle.rotate(90, Image.Resampling.BICUBIC)
    image.alpha_composite(needle, origin)
    image.alpha_composite(colored(dial, palette["dial"]).resize((texture_size, texture_size), Image.Resampling.LANCZOS), origin)
    draw = ImageDraw.Draw(image)
    draw.text((width // 2, 12 * scale), "Prévia das texturas", font=font(10 * scale),
              fill=(168, 175, 183, 255), anchor="mt")
    for index, label in enumerate(("0", "12.5k", "25k", "37.5k", "50k")):
        angle = pi * (1 - index / 4)
        point = (center[0] + cos(angle) * 94 * scale, center[1] - sin(angle) * 94 * scale)
        draw.text(point, label, font=font(10 * scale), fill=palette["text"], anchor="mm")
    draw.text((width // 2, 160 * scale), "25,000 XP/h", font=font(17 * scale), fill=palette["dial"], anchor="mm")
    draw.text((width // 2, 192 * scale), "Ampliação 3× · não é uma captura do WoW",
              font=font(8 * scale), fill=(139, 146, 154, 255), anchor="mm")
    image.convert("RGB").save(OUTPUT / "SpeedometerPreview.png")


if __name__ == "__main__":
    TEXTURES.mkdir(parents=True, exist_ok=True)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    dial, needle = make_dial(), make_needle()
    make_preview(dial, needle)
    print(TEXTURES / "SpeedometerDial.tga")
    print(TEXTURES / "SpeedometerNeedle.tga")
    print(OUTPUT / "SpeedometerPreview.png")
