# Mirage ![Latest release](https://img.shields.io//github/v/release/mirukana/mirage)

[Features](#currently-implemented-features) ⬥
[Installation](INSTALL.MD) ⬥
[Configuration & Theming](#configuration--theming) ⬥
[Screenshots](#more-screenshots)

A fancy, customizable, keyboard-operable [Matrix](https://matrix.org/) chat
client for encrypted and decentralized communication.  
Written in Qt/QML + Python with [nio](https://github.com/poljar/matrix-nio),
**currently in alpha**.

![Chat screenshot](extra/general/screenshots/01-chat.png?raw=true)

## Currently Implemented Features

### Client

- **Fluid interface** that adapts to any window size
- Customizable **keyboard shortcuts** for (almost) everything, including
  filtering and switching rooms, scrolling, sending files...
- Versatile **theming system**, properties can refer to each others and have 
  any valid ECMAScript 7 expression as value
  - Comes by default with **dark** and **transparent themes**
- **Multiple accounts** in one client

### Profile

- Set your display name and profile picture
- Import/export **E2E** key files

### Rooms

- Create, join, leave and forget rooms
- Send, accept and refuse invites

### Messages

- Send and receive **E2E encrypted messages**
- Send and receive emote messages (e.g. `/me reads attentively`)
- Receive notice (bot) messages
- Send **markdown** formatted messages
  - Additional syntax for **coloring** text, e.g. `<red>(Some text...)` - 
    [SVG/CSS color names](https://www.december.com/html/spec/colorsvg.html),
    and `#hex` codes can be used
- Send and receive normal or **E2E encrypted files**
- Client-side Matrix & HTTP URL **image previews**, including animated GIF 

### Presence

- Typing notifications

## Installation

See [INSTALL.MD](INSTALL.MD)

## Configuration & Theming

The config file can be found at *$XDG_CONFIG_HOME/mirage/settings.json*, 
or *~/.config/mirage/settings.json*.

The `theme` setting can be:

- The name of a built-in theme (`Midnight` or `Glass`)
- The filename without extension of a custom theme at 
  *$XDG_DATA_HOME/mirage/themes*, or *~/.local/share/mirage/themes*

A default theme from this repository can be copied to use as a base and edit,
for example:

```sh
    cp mirage/src/themes/Midnight.qpl \
       "${XDG_DATA_HOME:-$HOME/.local/share}/mirage/themes/MyTheme.qpl"
```

The config setting `theme` would need to be set to `MyTheme` in this case.

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


With `Alt+Shift+R` by default, the config and theme can be reloaded without 
restarting the app.

**Warnings**: 

- API currently unstable: theme properties are often renamed, added or deleted.
- The file format for both config and themes will soon change
- The current file format currently forces all theme to have all properties
  defined, instead of being able to only specify the ones to override from the
  default theme.

GUI settings will also be implemented in the future.

## Screenshots

![Sign-in](extra/general/screenshots/02-sign-in.png)
![Account settings](extra/general/screenshots/03-account-settings.png)
![Room creation](extra/general/screenshots/04-create-room.png)
![Chat](extra/general/screenshots/01-chat.png?raw=true)
![Main pane in small window](extra/general/screenshots/05-main-pane-small.png)
![Chat in small window](extra/general/screenshots/06-chat-small.png)
![Room pane in small window](extra/general/screenshots/07-room-pane-small.png)

