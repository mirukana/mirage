# Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
# SPDX-License-Identifier: LGPL-3.0-or-later

"""Provide the `Color` class and functions to easily construct a `Color`."""

import builtins
import colorsys
from copy import copy
from dataclasses import InitVar, dataclass, field
from enum import Enum
from typing import Optional, Tuple, Union

from hsluv import hex_to_hsluv, hsluv_to_hex, hsluv_to_rgb, rgb_to_hsluv

ColorTuple = Tuple[float, float, float, float]


@dataclass(repr=False)
class Color:
    """A color manipulable in HSLuv, HSL, RGB, hexadecimal and by SVG name.

    The `Color` object constructor accepts hexadecimal string
    ("#RGB", "#RRGGBB" or "#RRGGBBAA") or another `Color` to copy.

    Attributes representing the color in HSLuv, HSL, RGB, hexadecimal and
    SVG name formats can be accessed and modified on these `Color` objects.

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

    color_or_hex: InitVar[str] = "#00000000"
    hue:          float        = field(init=False, default=0)
    _saturation:  float        = field(init=False, default=0)
    _luv:         float        = field(init=False, default=0)
    alpha:        float        = field(init=False, default=1)

    def __post_init__(self, color_or_hex: Union["Color", str]) -> None:
        if isinstance(color_or_hex, Color):
            hsluva = color_or_hex.hsluva
            self.hue, self.saturation, self.luv, self.alpha = hsluva
        else:
            self.hex = color_or_hex

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
        alpha = f"0{alpha}" if len(alpha) == 1 else alpha
        return f"{alpha if self.alpha < 1 else ''}{rgb}".lower()

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
        try:
            return SVGColor(self.hex).name
        except ValueError:
            return None

    @name.setter
    def name(self, value: str) -> None:
        self.hex = SVGColor[value.lower()].value.hex

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


class SVGColor(Enum):
    """Standard SVG/HTML/CSS colors, with the addition of `transparent`."""

    aliceblue            = Color("#f0f8ff")
    antiquewhite         = Color("#faebd7")
    aqua                 = Color("#00ffff")
    aquamarine           = Color("#7fffd4")
    azure                = Color("#f0ffff")
    beige                = Color("#f5f5dc")
    bisque               = Color("#ffe4c4")
    black                = Color("#000000")
    blanchedalmond       = Color("#ffebcd")
    blue                 = Color("#0000ff")
    blueviolet           = Color("#8a2be2")
    brown                = Color("#a52a2a")
    burlywood            = Color("#deb887")
    cadetblue            = Color("#5f9ea0")
    chartreuse           = Color("#7fff00")
    chocolate            = Color("#d2691e")
    coral                = Color("#ff7f50")
    cornflowerblue       = Color("#6495ed")
    cornsilk             = Color("#fff8dc")
    crimson              = Color("#dc143c")
    cyan                 = Color("#00ffff")
    darkblue             = Color("#00008b")
    darkcyan             = Color("#008b8b")
    darkgoldenrod        = Color("#b8860b")
    darkgray             = Color("#a9a9a9")
    darkgreen            = Color("#006400")
    darkgrey             = Color("#a9a9a9")
    darkkhaki            = Color("#bdb76b")
    darkmagenta          = Color("#8b008b")
    darkolivegreen       = Color("#556b2f")
    darkorange           = Color("#ff8c00")
    darkorchid           = Color("#9932cc")
    darkred              = Color("#8b0000")
    darksalmon           = Color("#e9967a")
    darkseagreen         = Color("#8fbc8f")
    darkslateblue        = Color("#483d8b")
    darkslategray        = Color("#2f4f4f")
    darkslategrey        = Color("#2f4f4f")
    darkturquoise        = Color("#00ced1")
    darkviolet           = Color("#9400d3")
    deeppink             = Color("#ff1493")
    deepskyblue          = Color("#00bfff")
    dimgray              = Color("#696969")
    dimgrey              = Color("#696969")
    dodgerblue           = Color("#1e90ff")
    firebrick            = Color("#b22222")
    floralwhite          = Color("#fffaf0")
    forestgreen          = Color("#228b22")
    fuchsia              = Color("#ff00ff")
    gainsboro            = Color("#dcdcdc")
    ghostwhite           = Color("#f8f8ff")
    gold                 = Color("#ffd700")
    goldenrod            = Color("#daa520")
    gray                 = Color("#808080")
    green                = Color("#008000")
    greenyellow          = Color("#adff2f")
    grey                 = Color("#808080")
    honeydew             = Color("#f0fff0")
    hotpink              = Color("#ff69b4")
    indianred            = Color("#cd5c5c")
    indigo               = Color("#4b0082")
    ivory                = Color("#fffff0")
    khaki                = Color("#f0e68c")
    lavender             = Color("#e6e6fa")
    lavenderblush        = Color("#fff0f5")
    lawngreen            = Color("#7cfc00")
    lemonchiffon         = Color("#fffacd")
    lightblue            = Color("#add8e6")
    lightcoral           = Color("#f08080")
    lightcyan            = Color("#e0ffff")
    lightgoldenrodyellow = Color("#fafad2")
    lightgray            = Color("#d3d3d3")
    lightgreen           = Color("#90ee90")
    lightgrey            = Color("#d3d3d3")
    lightpink            = Color("#ffb6c1")
    lightsalmon          = Color("#ffa07a")
    lightseagreen        = Color("#20b2aa")
    lightskyblue         = Color("#87cefa")
    lightslategray       = Color("#778899")
    lightslategrey       = Color("#778899")
    lightsteelblue       = Color("#b0c4de")
    lightyellow          = Color("#ffffe0")
    lime                 = Color("#00ff00")
    limegreen            = Color("#32cd32")
    linen                = Color("#faf0e6")
    magenta              = Color("#ff00ff")
    maroon               = Color("#800000")
    mediumaquamarine     = Color("#66cdaa")
    mediumblue           = Color("#0000cd")
    mediumorchid         = Color("#ba55d3")
    mediumpurple         = Color("#9370db")
    mediumseagreen       = Color("#3cb371")
    mediumslateblue      = Color("#7b68ee")
    mediumspringgreen    = Color("#00fa9a")
    mediumturquoise      = Color("#48d1cc")
    mediumvioletred      = Color("#c71585")
    midnightblue         = Color("#191970")
    mintcream            = Color("#f5fffa")
    mistyrose            = Color("#ffe4e1")
    moccasin             = Color("#ffe4b5")
    navajowhite          = Color("#ffdead")
    navy                 = Color("#000080")
    oldlace              = Color("#fdf5e6")
    olive                = Color("#808000")
    olivedrab            = Color("#6b8e23")
    orange               = Color("#ffa500")
    orangered            = Color("#ff4500")
    orchid               = Color("#da70d6")
    palegoldenrod        = Color("#eee8aa")
    palegreen            = Color("#98fb98")
    paleturquoise        = Color("#afeeee")
    palevioletred        = Color("#db7093")
    papayawhip           = Color("#ffefd5")
    peachpuff            = Color("#ffdab9")
    peru                 = Color("#cd853f")
    pink                 = Color("#ffc0cb")
    plum                 = Color("#dda0dd")
    powderblue           = Color("#b0e0e6")
    purple               = Color("#800080")
    rebeccapurple        = Color("#663399")
    red                  = Color("#ff0000")
    rosybrown            = Color("#bc8f8f")
    royalblue            = Color("#4169e1")
    saddlebrown          = Color("#8b4513")
    salmon               = Color("#fa8072")
    sandybrown           = Color("#f4a460")
    seagreen             = Color("#2e8b57")
    seashell             = Color("#fff5ee")
    sienna               = Color("#a0522d")
    silver               = Color("#c0c0c0")
    skyblue              = Color("#87ceeb")
    slateblue            = Color("#6a5acd")
    slategray            = Color("#708090")
    slategrey            = Color("#708090")
    snow                 = Color("#fffafa")
    springgreen          = Color("#00ff7f")
    steelblue            = Color("#4682b4")
    tan                  = Color("#d2b48c")
    teal                 = Color("#008080")
    thistle              = Color("#d8bfd8")
    tomato               = Color("#ff6347")
    transparent          = Color("#00000000")  # not standard but exists in QML
    turquoise            = Color("#40e0d0")
    violet               = Color("#ee82ee")
    wheat                = Color("#f5deb3")
    white                = Color("#ffffff")
    whitesmoke           = Color("#f5f5f5")
    yellow               = Color("#ffff00")
    yellowgreen          = Color("#9acd32")


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


# Aliases
color = Color
hsluv = hsluva
hsl   = hsla
rgb   = rgba
