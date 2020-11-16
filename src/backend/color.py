# Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
# SPDX-License-Identifier: LGPL-3.0-or-later

"""Provide the `Color` class and functions to easily construct a `Color`."""

import builtins
import colorsys
from copy import copy
from dataclasses import InitVar, dataclass, field
from typing import Optional, Tuple, Union

from hsluv import hex_to_hsluv, hsluv_to_hex, hsluv_to_rgb, rgb_to_hsluv

from .svg_colors import SVG_COLORS

HEX_TO_SVG = {v: k for k, v in SVG_COLORS.items()}

ColorTuple = Tuple[float, float, float, float]


@dataclass(repr=False)
class Color:
    """A color manipulable in HSLuv, HSL, RGB, hexadecimal and by SVG name.

    The `Color` object constructor accepts hexadecimal string
    ("#RGB", "#RRGGBB" or "#RRGGBBAA"),
    [CSS/SVG named colors](https://www.december.com/html/spec/colorsvg.html),
    or another `Color` to copy.

    Attributes representing the color in HSLuv, HSL, RGB and hexadecimal
    formats can be accessed and modified on these `Color` objects.

    The `hsluv()`/`hsluva()`, `hsl()`/`hsla()` and `rgb()`/`rgba()`
    functions in this module are provided to create an object by specifying
    a color in other formats.

    Copies of objects with modified attributes can be created with the
    with the `Color.but()`, `Color.plus()` and `Copy.times()` methods.

    If the `hue` is outside of the normal 0-359 range, the number is
    interpreted as `hue % 360`, e.g.  `360` is `0`, `460` is `100`,
    or `-20` is `340`.
    """

    # The saturation and luv are properties due to the need for a setter
    # capping the value between 0-100, as hsluv handles numbers outside
    # this range incorrectly.

    color_hex_or_name: InitVar[str] = "black"
    hue:               float        = field(init=False, default=0)
    _saturation:       float        = field(init=False, default=0)
    _luv:              float        = field(init=False, default=0)
    alpha:             float        = field(init=False, default=1)

    def __post_init__(self, color_hex_or_name: Union["Color", str]) -> None:
        if isinstance(color_hex_or_name, Color):
            hsluva = color_hex_or_name.hsluva
            self.hue, self.saturation, self.luv, self.alpha = hsluva
        elif color_hex_or_name.startswith("#"):
            self.hex = color_hex_or_name
        else:
            self.name = color_hex_or_name

    # HSLuv

    @property
    def hsluva(self) -> ColorTuple:
        return (self.hue, self.saturation, self.luv, self.alpha)

    @hsluva.setter
    def hsluva(self, value: ColorTuple) -> None:
        self.hue, self.saturation, self.luv, self.alpha = value

    @property
    def saturation(self) -> float:
        return self._saturation

    @saturation.setter
    def saturation(self, value: float) -> None:
        self._saturation = max(0, min(100, value))

    @property
    def luv(self) -> float:
        return self._luv

    @luv.setter
    def luv(self, value: float) -> None:
        self._luv = max(0, min(100, value))

    # HSL

    @property
    def hsla(self) -> ColorTuple:
        r, g, b = (self.red / 255, self.green / 255, self.blue / 255)
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        return (h * 360, s * 100, l * 100, self.alpha)

    @hsla.setter
    def hsla(self, value: ColorTuple) -> None:
        h, s, l   = (value[0] / 360, value[1] / 100, value[2] / 100)  # noqa
        r, g, b   = colorsys.hls_to_rgb(h, l, s)
        self.rgba = (r * 255, g * 255, b * 255, value[3])

    @property
    def light(self) -> float:
        return self.hsla[2]

    @light.setter
    def light(self, value: float) -> None:
        self.hsla = (self.hue, self.saturation, value, self.alpha)

    # RGB

    @property
    def rgba(self) -> ColorTuple:
        r, g, b = hsluv_to_rgb(self.hsluva)
        return r * 255, g * 255, b * 255, self.alpha

    @rgba.setter
    def rgba(self, value: ColorTuple) -> None:
        r, g, b     = (value[0] / 255, value[1] / 255, value[2] / 255)
        self.hsluva = rgb_to_hsluv((r, g, b)) + (self.alpha,)

    @property
    def red(self) -> float:
        return self.rgba[0]

    @red.setter
    def red(self, value: float) -> None:
        self.rgba = (value, self.green, self.blue, self.alpha)

    @property
    def green(self) -> float:
        return self.rgba[1]

    @green.setter
    def green(self, value: float) -> None:
        self.rgba = (self.red, value, self.blue, self.alpha)

    @property
    def blue(self) -> float:
        return self.rgba[2]

    @blue.setter
    def blue(self, value: float) -> None:
        self.rgba = (self.red, self.green, value, self.alpha)

    # Hexadecimal

    @property
    def hex(self) -> str:
        rgb   = hsluv_to_hex(self.hsluva)
        alpha = builtins.hex(int(self.alpha * 255))[2:]
        return f"{rgb}{alpha if self.alpha < 1 else ''}".lower()

    @hex.setter
    def hex(self, value: str) -> None:
        if len(value) == 4:
            template = "#{r}{r}{g}{g}{b}{b}"
            value    = template.format(r=value[1], g=value[2], b=value[3])

        alpha = int(value[-2:] if len(value) == 9 else "ff", 16) / 255

        self.hsluva = hex_to_hsluv(value) + (alpha,)

    # name color

    @property
    def name(self) -> Optional[str]:
        return HEX_TO_SVG.get(self.hex)

    @name.setter
    def name(self, value: str) -> None:
        self.hex = SVG_COLORS[value.lower()]

    # Other methods

    def __repr__(self) -> str:
        r, g, b   = int(self.red), int(self.green), int(self.blue)
        h, s, luv = int(self.hue), int(self.saturation), int(self.luv)
        l         = int(self.light)  # noqa
        a         = self.alpha
        block     = f"\x1b[38;2;{r};{g};{b}m█████\x1b[0m"
        sep       = "\x1b[1;33m/\x1b[0m"
        end       = f" {sep} {self.name}" if self.name else ""
        # Need a terminal with true color support to render the block!
        return (
            f"{block} hsluva({h}, {s}, {luv}, {a}) {sep} "
            f"hsla({h}, {s}, {l}, {a}) {sep} rgba({r}, {g}, {b}, {a}) {sep} "
            f"{self.hex}{end}"
        )

    def but(
        self,
        hue:        Optional[float]      = None,
        saturation: Optional[float]      = None,
        luv:        Optional[float]      = None,
        alpha:      Optional[float]      = None,
        *,
        hsluva:     Optional[ColorTuple] = None,
        hsla:       Optional[ColorTuple] = None,
        rgba:       Optional[ColorTuple] = None,
        hex:        Optional[str]        = None,
        name:       Optional[str]        = None,
        light:      Optional[float]      = None,
        red:        Optional[float]      = None,
        green:      Optional[float]      = None,
        blue:       Optional[float]      = None,
    ) -> "Color":
        """Return a copy of this `Color` with overriden attributes.

        Example:
        >>> first  = Color(100, 50, 50)
        >>> second = c.but(hue=20, saturation=100)
        >>> second.hsluva
        (20, 50, 100, 1)
        """

        new = copy(self)

        for arg, value in locals().items():
            if arg not in ("new", "self") and value is not None:
                setattr(new, arg, value)

        return new

    def plus(
        self,
        hue:        Optional[float] = None,
        saturation: Optional[float] = None,
        luv:        Optional[float] = None,
        alpha:      Optional[float] = None,
        *,
        light:      Optional[float] = None,
        red:        Optional[float] = None,
        green:      Optional[float] = None,
        blue:       Optional[float] = None,
    ) -> "Color":
        """Return a copy of this `Color` with values added to attributes.

        Example:
        >>> first  = Color(100, 50, 50)
        >>> second = c.plus(hue=10, saturation=-20)
        >>> second.hsluva
        (110, 30, 50, 1)
        """

        new = copy(self)

        for arg, value in locals().items():
            if arg not in ("new", "self") and value is not None:
                setattr(new, arg, getattr(self, arg) + value)

        return new

    def times(
        self,
        hue:        Optional[float] = None,
        saturation: Optional[float] = None,
        luv:        Optional[float] = None,
        alpha:      Optional[float] = None,
        *,
        light:      Optional[float] = None,
        red:        Optional[float] = None,
        green:      Optional[float] = None,
        blue:       Optional[float] = None,
    ) -> "Color":
        """Return a copy of this `Color` with multiplied attributes.

        Example:
        >>> first  = Color(100, 50, 50, 0.8)
        >>> second = c.times(luv=2, alpha=0.5)
        >>> second.hsluva
        (100, 50, 100, 0.4)
        """

        new = copy(self)

        for arg, value in locals().items():
            if arg not in ("new", "self") and value is not None:
                setattr(new, arg, getattr(self, arg) * value)

        return new


def hsluva(
    hue: float = 0, saturation: float = 0, luv: float = 0, alpha: float = 1,
) -> Color:
    """Return a `Color` from `(0-359, 0-100, 0-100, 0-1)` HSLuv arguments."""
    return Color().but(hue, saturation, luv, alpha)


def hsla(
    hue: float = 0, saturation: float = 0, light: float = 0, alpha: float = 1,
) -> Color:
    """Return a `Color` from `(0-359, 0-100, 0-100, 0-1)` HSL arguments."""
    return Color().but(hue, saturation, light=light, alpha=alpha)


def rgba(
    red: float = 0, green: float = 0, blue: float = 0, alpha: float = 1,
) -> Color:
    """Return a `Color` from `(0-255, 0-255, 0-255, 0-1)` RGB arguments."""
    return Color().but(red=red, green=green, blue=blue, alpha=alpha)


color = Color
hsluv = hsluva
hsl   = hsla
rgb   = rgba
