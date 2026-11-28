"""Generate the gauge's transparent TGA textures and a local PNG preview.

Development dependencies: Pillow and Lupa (Lua 5.1). Run from anywhere with Python 3.
"""

from math import ceil, cos, floor, hypot, pi, sin
from pathlib import Path

from lupa.lua51 import LuaRuntime
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
TEXTURES = ROOT / "src" / "textures"
OUTPUT = ROOT / "dist"
TEXTURE_SIZE = 512
WHITE = (255, 255, 255, 255)


def load_definition():
    # Share the actual Lua geometry and palette with the rendered component.
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute('PerHour = { Components={}, AddonName="per-hour" }')
    lua.execute((ROOT / "src" / "core" / "Theme.lua").read_text(encoding="utf-8"))
    lua.execute((ROOT / "src" / "core" / "Speedometer.lua").read_text(encoding="utf-8"))
    theme = lua.globals().PerHour.Theme

    def rgba(color):
        channels = [color[index] for index in range(1, len(color) + 1)]
        if len(channels) == 3:
            channels.append(1)
        return tuple(floor(channel * 255 + 0.5) for channel in channels)

    palette = {
        "dial": rgba(theme.gold.text),
        "needle": rgba(theme.speedometer.needle),
        "shadow": rgba(theme.speedometer.shadow),
        "text": rgba(theme.text),
    }
    return palette, dict(lua.globals().PerHour.Components.SpeedometerGeometry.items())


PALETTE, GEOMETRY = load_definition()
SIZE, RADIUS = int(GEOMETRY["TextureSize"]), GEOMETRY["Radius"]


def position(fraction, radius):
    angle = pi * (1 - fraction)
    return SIZE / 2 + cos(angle) * radius, SIZE / 2 - sin(angle) * radius


def segment(x1, y1, x2, y2, half_width=0):
    dx, dy = x2 - x1, y2 - y1
    return x1, y1, dx, dy, 1 / (dx * dx + dy * dy), half_width


def segment_distance(x, y, line):
    x1, y1, dx, dy, inverse_length, half_width = line
    offset_x, offset_y = x - x1, y - y1
    fraction = min(1, max(0, (offset_x * dx + offset_y * dy) * inverse_length))
    return hypot(offset_x - fraction * dx, offset_y - fraction * dy) - half_width


def finish(distance, bounds, name):
    # Bake analytic coverage directly into the final texture: no low-resolution
    # intermediate, enlargement, blur or repeated resampling of the contour.
    density = TEXTURE_SIZE / SIZE
    alpha = Image.new("L", (TEXTURE_SIZE, TEXTURE_SIZE))
    pixels = alpha.load()
    left, top, right, bottom = bounds
    feather = GEOMETRY["EdgeCoverage"]
    for row in range(max(0, floor((top - feather) * density)), min(TEXTURE_SIZE, ceil((bottom + feather) * density))):
        y = (row + 0.5) / density
        for column in range(max(0, floor((left - feather) * density)), min(TEXTURE_SIZE, ceil((right + feather) * density))):
            x = (column + 0.5) / density
            coverage = min(1, max(0, 0.5 - distance(x, y) / feather))
            pixels[column, row] = floor(coverage * 255 + 0.5)
    image = Image.new("RGBA", alpha.size, WHITE)
    image.putalpha(alpha)
    image.save(TEXTURES / name)
    return image


def make_dial():
    center = SIZE / 2
    ticks = []
    for index in range(21):
        major = index % 5 == 0
        start = position(index / 20, RADIUS)
        end = position(index / 20, RADIUS - GEOMETRY["MajorTickLength" if major else "MinorTickLength"])
        ticks.append(segment(*start, *end, (2 if major else 1) / 2))

    def distance(x, y):
        dx, dy = x - center, y - center
        arc = max(abs(hypot(dx, dy) - RADIUS) - GEOMETRY["ArcWidth"] / 2, dy)
        cap = hypot(dx, dy) - GEOMETRY["CapRadius"]
        result = min(arc, cap)
        for tick in ticks:
            result = min(result, segment_distance(x, y, tick))
        return result

    return finish(distance, (center - RADIUS - 2, center - RADIUS - 2,
                            center + RADIUS + 2, center + GEOMETRY["CapRadius"] + 1), GEOMETRY["ArcTexture"])


def make_needle():
    center = SIZE / 2
    tip = center + RADIUS - GEOMETRY["NeedleInset"]
    base_width, tip_width = GEOMETRY["NeedleBaseWidth"], GEOMETRY["NeedleTipWidth"]
    vertices = ((center, center - base_width / 2), (tip, center - tip_width / 2),
                (tip, center + tip_width / 2), (center, center + base_width / 2))
    edges = [segment(*vertices[index], *vertices[(index + 1) % len(vertices)]) for index in range(len(vertices))]

    def distance(x, y):
        nearest, inside = float("inf"), True
        for edge in edges:
            x1, y1, dx, dy, _, _ = edge
            inside = inside and dx * (y - y1) - dy * (x - x1) >= 0
            nearest = min(nearest, segment_distance(x, y, edge))
        return -nearest if inside else nearest

    return finish(distance, (center, center - base_width / 2, tip, center + base_width / 2), GEOMETRY["NeedleTexture"])


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


def render_gauge(dial, needle, width, fraction, zoom):
    labels = ("0", "12.5k", "25k", "37.5k", "50k")
    label_size = int(GEOMETRY["LabelSize"])
    label_widths = [ceil(font(label_size).getlength(text)) for text in labels]
    radius = width / 2 - GEOMETRY["Padding"]
    for index, label_width in enumerate(label_widths):
        cosine = abs(cos(pi * (1 - index / 4)))
        if cosine > 0.001:
            radius = min(radius, (width / 2 - GEOMETRY["Padding"] - label_width) / cosine - GEOMETRY["LabelGap"])
    radius = max(16, radius)
    bottom = -GEOMETRY["LabelHeight"] / 2 - GEOMETRY["Padding"]
    top = radius + GEOMETRY["LabelGap"] + GEOMETRY["LabelHeight"] + GEOMETRY["Padding"]
    height = ceil(top - bottom)
    center_y = -height / 2 - bottom
    image = Image.new("RGBA", (round(width * zoom), round(height * zoom)), (16, 18, 20, 255))
    pivot = (width * zoom / 2, (height / 2 - center_y) * zoom)
    density = TEXTURE_SIZE / (SIZE * radius / RADIUS * zoom)
    for artwork, color, shadow, rotation in (
        (dial, PALETTE["shadow"], True, 0),
        (needle, PALETTE["shadow"], True, pi * (1 - fraction)),
        (needle, PALETTE["needle"], False, pi * (1 - fraction)),
        (dial, PALETTE["dial"], False, 0),
    ):
        pivot_x, pivot_y = pivot
        if shadow:
            pivot_x, pivot_y = pivot_x + zoom, pivot_y + zoom
        a, b = cos(rotation) * density, -sin(rotation) * density
        d, e = sin(rotation) * density, cos(rotation) * density
        transform = (a, b, TEXTURE_SIZE / 2 - a * pivot_x - b * pivot_y,
                     d, e, TEXTURE_SIZE / 2 - d * pivot_x - e * pivot_y)
        # Point-sampled bilinear transform, closer to the game's LINEAR GPU
        # sampling than a preview that hides aliasing with Lanczos downsampling.
        layer = colored(artwork, color).transform(image.size, Image.Transform.AFFINE, transform,
                                                 resample=Image.Resampling.BILINEAR)
        image.alpha_composite(layer)
    draw = ImageDraw.Draw(image)
    for index, label in enumerate(labels):
        angle = pi * (1 - index / 4)
        point = (pivot[0] + cos(angle) * (radius + GEOMETRY["LabelGap"]) * zoom,
                 pivot[1] - sin(angle) * (radius + GEOMETRY["LabelGap"]) * zoom)
        draw.text(point, label, font=font(label_size * zoom), fill=PALETTE["text"], anchor=("rm", "rb", "mb", "lb", "lm")[index])
    return image


def make_preview(dial, needle):
    image = Image.new("RGBA", (990, 385), (16, 18, 20, 255))
    draw = ImageDraw.Draw(image)
    draw.text((18, 12), "Compact gauge: fixed 10 px labels; geometry resized independently",
              font=font(15), fill=PALETTE["text"])
    for index, width in enumerate((100, 120, 160)):
        x = index * 330 + 165
        draw.text((x, 50), f"{width} px wide / native size", font=font(12), fill=PALETTE["text"], anchor="mm")
        native = render_gauge(dial, needle, width, (0.2, 0.5, 0.8)[index], 1)
        image.alpha_composite(native, (x - native.width // 2, 72))
        draw.text((x, 170), "2x inspection", font=font(11), fill=(168, 175, 183, 255), anchor="mm")
        enlarged = render_gauge(dial, needle, width, (0.2, 0.5, 0.8)[index], 2)
        image.alpha_composite(enlarged, (x - enlarged.width // 2, 190))
    draw.text((18, 364), "Texture/font preview only; not a WoW screenshot.", font=font(11), fill=(168, 175, 183, 255))
    image.convert("RGB").save(OUTPUT / "SpeedometerPreview.png")


if __name__ == "__main__":
    TEXTURES.mkdir(parents=True, exist_ok=True)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    dial, needle = make_dial(), make_needle()
    make_preview(dial, needle)
    print(TEXTURES / GEOMETRY["ArcTexture"])
    print(TEXTURES / GEOMETRY["NeedleTexture"])
    print(OUTPUT / "SpeedometerPreview.png")
