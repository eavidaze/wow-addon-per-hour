"""Bake MUI CircularProgress motion into a native WoW flipbook texture.

Motion reference (MIT): packages/mui-material/src/CircularProgress/CircularProgress.js
https://github.com/mui/material-ui -- Copyright (c) 2014 Call-Em-All.
See src/licenses/MaterialUI.txt. Requires Pillow and Lupa (Lua 5.1).
"""
from math import atan2, cos, floor, hypot, pi, sin
from pathlib import Path
from lupa.lua51 import LuaRuntime
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('PerHour={Components={}}')
lua.execute((ROOT/'src/core/Theme.lua').read_text(encoding='utf-8'))
lua.execute((ROOT/'src/core/SessionIndicator.lua').read_text(encoding='utf-8'))
STYLE = dict(lua.globals().PerHour.Components.SessionIndicatorStyle.items())


def ease_in_out(progress):
    """CSS ease-in-out: cubic-bezier(.42, 0, .58, 1), inverted by x."""
    low, high = 0.0, 1.0
    for _ in range(28):
        t = (low+high)/2
        x = 3*(1-t)**2*t*.42 + 3*(1-t)*t*t*.58 + t**3
        if x < progress:
            low = t
        else:
            high = t
    t = (low+high)/2
    return 3*(1-t)*t*t+t**3


def motion(progress):
    """MUI: continuous rotation plus independently eased dash/offset keyframes."""
    half = progress < .5
    eased = ease_in_out(progress*2 if half else (progress-.5)*2)
    length = STYLE['DashMin']+(STYLE['DashMax']-STYLE['DashMin'])*(eased if half else 1-eased)
    offset = STYLE['OffsetMiddle']*eased if half else STYLE['OffsetMiddle']+(STYLE['OffsetEnd']-STYLE['OffsetMiddle'])*eased
    circumference = pi*(STYLE['ReferenceSize']-STYLE['ReferenceStroke'])
    return 2*pi*(progress-offset/circumference), 2*pi*length/circumference


def render_frame(progress):
    resolution = int(STYLE['FrameSize'])
    density = resolution/STYLE['Size']
    center, radius, half_stroke = STYLE['Size']/2, STYLE['Radius'], STYLE['Stroke']/2
    start, sweep = motion(progress)
    end = start+sweep
    start_point, end_point = (radius*cos(start),radius*sin(start)),(radius*cos(end),radius*sin(end))
    alpha = Image.new('L',(resolution,resolution))
    pixels = alpha.load()
    for row in range(resolution):
        y = (row+.5)/density-center
        for column in range(resolution):
            x = (column+.5)/density-center
            angle = (atan2(y,x)-start) % (2*pi)
            distance = abs(hypot(x,y)-radius)-half_stroke if angle <= sweep else min(
                hypot(x-start_point[0],y-start_point[1]),hypot(x-end_point[0],y-end_point[1]))-half_stroke
            coverage = max(0,min(1,.5-distance/STYLE['EdgeCoverage']))
            pixels[column,row] = floor(coverage*255+.5)
    image = Image.new('RGBA',alpha.size,(255,255,255,255))
    image.putalpha(alpha)
    return image


if __name__ == '__main__':
    columns, rows, count, size = (int(STYLE[key]) for key in ('Columns','Rows','Frames','FrameSize'))
    assert count <= columns*rows
    sheet = Image.new('RGBA',(columns*size,rows*size),(255,255,255,0))
    frames = [render_frame(index/count) for index in range(count)]
    for index,frame in enumerate(frames):
        sheet.paste(frame,((index % columns)*size,(index//columns)*size))
    destination = ROOT/'src/textures'/STYLE['Texture']
    sheet.save(destination)
    print(destination)
