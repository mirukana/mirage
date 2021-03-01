# Theming

A default theme from this repository can be copied to use as a base and edit,
for example:

```sh
    cp mirage/src/themes/Midnight.qpl \
       "${XDG_DATA_HOME:-$HOME/.local/share}/mirage/themes/MyTheme.qpl"
```

Or for Flatpak users:

```sh
    cp mirage/src/themes/Midnight.qpl \
       ~/.var/app/io.github.mirukana.mirage/data/mirage/themes/MyTheme.qpl
```

The `theme` property in [`settings.py`](CONFIG.md#settingspy) would need
to be set to `MyTheme.qpl` in this case.

Theme files are nested-by-indentations sections of properties and values.  
Properties are declared as `<type> <name>: <value>`.  
Values can be any JavaScript (ECMAScript 7) expressions.

Most of the properties are of type `color`.
Their values, if not just refering to another property,
can be expressed with a:

- [SVG/CSS color name](https://www.december.com/html/spec/colorsvg.html)
  string, e.g. `"blue"`
- Hexadecimal code string, e.g. `"#fff"` or `"#cc0000"`
- RGBA value, using the `Qt.rgba(0-1, 0-1, 0-1, 0-1)` function
- HSLA value, using the `Qt.hsla(0-1, 0-1, 0-1, 0-1)` function
- HSVA value, using the `Qt.hsva(0-1, 0-1, 0-1, 0-1)` function
- [HSLUV](https://www.hsluv.org/) value, using the
  `hsluv(0-360, 0-100, 0-100, 0-1)` function. This is the prefered method 
  used throughout the default theme files
  (why? see [this](https://www.hsluv.org/comparison/#rainbow-hsluv) and
  [that](https://www.boronine.com/2012/03/26/Color-Spaces-for-Human-Beings/#hsl-is-a-lemon))

If you just want to change the background picture,
or use a gradient/simple color instead, search for the `ui:` section in your
text editor.

When an in-use theme file is saved while the application is running, it 
will automatically be reloaded and changes will be seen immediatly.

You can manually trigger a reload by updating the file's last change timestamp,
e.g. with the `touch` command: 

```sh
touch ~/.config/mirage/settings.py
```

**Warnings**: 

- The current file format forces all theme to have all properties
  defined, instead of being able to only specify the ones to override from the
  default theme. Keep this in mind when updating Mirage.

- Themes will soon be moved to the PCN format, that was introduced in 0.7.0 
  for user config files.
