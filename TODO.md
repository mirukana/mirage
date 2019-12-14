# TODO

## Media

- Handle set avatar upload errors
- Support encrypted m.file
- Confirmation box after picking file to upload
- Show real progression for mxc thumbnail loadings

- Show reason under broken thumbnail icons
- Support m.file thumbnails
- Generate video thumbnails
- GIFs can use the video player
- Display GIF static thumbnails while the real GIF is loading
- Video bug: when media is done playing, clicking on progress slider always
  bring back to the beginning no matter where
- Video: missing buttons and small size problems
- Audio: online playback is buggy, must download+play file
- EventLink
  - Special treatment for matrix.to URLs?
- EventFile & Downloading (right click on media > save as...)
- Prevent using upload keybinds in rooms with no perms

## Refactoring

- Account settings with `HTabbedContainer`
  - Get rid of all `currentSpacing` stuff
  - Use new default/reset controls system 
- Split `HScrollableTextArea`
- Composer
- Missing room keybinds (invite, etc), and don't put all the binds in 
  one central file (else we can only rely on uiState properties)
- Use QML states
- Use a singleton for utils.js
- Try gel for the models and stop being lazy in python

- Room Sidepane save/load size & keybinds

## Bug fixes

- Retry the initial profile retrieval if it fails (due to e.g. dead server)
- Pausing uploads doesn't work well with matrix.org
- Quickly posting with another account leads to sync stop
- CPU usage
- `code` not colored in room subtitle
- In the "Leave me" room, "join > Hi > left" aren't combined
- Event delegates changing height don't scroll the list
- When selecting text and scrolling up, selection stops working after a while
  - Ensure all the text that should be copied is copied
  - Multiple messages are currently copied out of order

- Pressing backspace in composer sometimes doesn't work
- Message order isn't preserved when sending a first message in a E2E
  room, then while keys are being shared sending one with another account,
  then sending one with the first account again

- If account not in config anymore, discard ui state last page on startup
- Do something when access token is invalid

- Don't store states in delegates
- [hr not working](https://bugreports.qt.io/browse/QTBUG-74342)
- Terrible performance using `QT_QPA_PLATFORM=wayland-egl`, must use `xcb`
- Quote links color in room subtitles (e.g. "> http://foo.orgA)" )

## Interface

- Make all "Cancel" buttons able to cancel running Backend coroutines set
  `disabledWhileLoading` to `false` for all "OK" buttons where it makes sense
- Use a loader of the swipeview containing members, settings, etc views
- Expand the room pane if it's too small to show room settings?
- Drop the `buttonModel`/`buttonCallbacks` HBox approach
- Scrollable popups and room settings
- HDrawer snapping
- Make theme error/etc text colors more like name colors
- In account settings, display name field text should be colored
- Way to open context menus without a right mouse button
- `smartVerticalFlick()` gradual acceleration
- Make banner buttons look better

- Choose a better default easing type for animations
- Make HListView scrollbars visible
- Remove first html lists left margin
- Adapt UI for small heights

- In room creation, click avatar to set the future room's avatar
- In join room page, show the matching room's avatar when typing
- In find someone page, show the matching user's avatar when typing

- Combine events so they take less space
  - After combining is implemented, no need to hide profile changes anymore.
- Replies
- Messages editing and redaction
- Code highlighting
- Adapt shortcuts flicking speed to font size 

- EditAccount page:
  - Device settings
  - Multiaccount aliases:
    - Warn when conflict with another alias
    - Forbid spaces?
    - Add an explanation tooltip
    - Prevent sending messages with an user not in room
    - Support \ escaping
  - Accept drag and dropping a picture to set avatar

- Add stuff to room tooltips like last messages
- Show something when connection is lost or 429s happen
- "Rejoin" LeftBanner button if room is public
- Daybreak color
- Conversation breaks: show time of first new msg after break instead of big
  blank space

- Sidepane
  - Animate when logging out last account and sidepane turns invisible
  - Header back button when reduced
  - Better look when reduced to minimum size

- Server selection
- Register/Reset for AddAccount page
- Prevent using an alias if that user is not in the room or no permission
- Spinner when loading past room events

- Theming
  - Bundle fonts
  - Standard file format, see *~ppy/qml_dict_theme.qml*
  - https://doc.qt.io/qt-5/qtquickcontrols2-customize.html#creating-a-custom-style
  - icons.preferredPack: accept multiple values
  - Find icon packs in user data dir
  - See [Text.fontSizeMode](https://doc.qt.io/qt-5/qml-qtquick-text.html#fontSizeMode-prop)
  - Way to round avatar corners to allow box radius
  - If avatar is set, name color from average color?
  - Accent color from background

- Settings page
- Notifications
- Opening links with keyboard
- Better `<pre>` 

- Custom file picker for Linux (...)

## Backend

- Saving the room settings
- Refetch profile after manual profile change, don't wait for a room event

- Prevent starting multiple client instances, causes problems with E2E DB
- Check if username exists on login screen
- [Soft logouts](https://github.com/poljar/matrix-nio/commit/aba10)
- `pyotherside.atexit()`
- Logout previous session if adding an account that's already connected
- Config file format

- Startup improvements
  - Initial sync filter to get more events on first sync
  - Lazy loading members
  - Store profiles, room events and states
  - Use AsyncClient `store_sync_tokens`
    - Make sure to all members are fetched before sending an E2E message 
    - Fetch all members when using the filter members bar

- Direct chats category
- Animate RoomEventDelegate DayBreak apparition
- Live-reloading accounts.json

- E2E
  - Device verification
  - Edit/delete own devices
  - Request room keys from own other devices
  - Auto-trust accounts within the same client
  - Provide help when undecryptable messages occur, including:
    - Trigger `nio.AsyncClient.request_room_key`
    - Option to export-logout-login-import to fix one-time key problems
- Read receipts
- Status message and presence

## Nio contributions

- Running blocking DB function calls in executor (WIP)
- `AsyncClient.share_group_session`: send device batches concurrently (WIP)

- Dedicated error for invalid password on key import
- `RoomMessageMedia` and `RoomAvatarEvent` info attributes
- Handle `m.room.aliases` events

- Support "Empty room (was ...)" after peer left
- Left room events after client reboot
- Previewing room without joining

- Get content repo config API
- Add the `resume()` account "login" method

- Turn all the Error and Response classes into exceptions and normal returns
  once `HttpClient` is deprecated

## Distribution

- Include python dependencies in binary with rcc?
- Improve the README.md

## Notable changes for future Qt version upgrade

### [Qt 5.13](https://wiki.qt.io/New_Features_in_Qt_5.13)

- Added `SplitView`
- Added `cache` property to icon

### [Qt 5.14](https://wiki.qt.io/New_Features_in_Qt_5.14)

- Applications can now opt-in to use non-integer scale factors.
  Use `QGuiApplication::highDpiScaleFactorRoundingPolicy`.

- Added `qmlRegisterSingletonInstance` function.
  This allows to expose a QObject as a singleton to QML, without having to
  create a factory function as required by `qmlRegisterSingletonType`.
  It is meant as a type safe replacement of `setContextProperty`.

- Added `qmlRegisterAnonymousType` as a replacement for `qmlRegisterType`.
  It allows to specify the URI and major version for better tooling support.

- qmllint gained an experimental -U option. If run with it, it warns about 
  about accesses to unqualified identifiers

- `Text` and `TextEdit` now support Markdown format
  (CommonMark and GitHub dialects) as an alternative to HTML.
  Includes the GitHub checklist extension, such that you can click to toggle
  checkboxes in a `TextEdit`.

- `TextEdit` uses an I-beam cursor by default, and a pointing-hand cursor when
  hovering a checkbox or a link

- Added `WheelHandler`, an Event Handler for the mouse wheel, and optionally
  for emulated mouse wheel events coming from a trackpad.

- Added `BoundaryRule` in Qt.labs.animation: a `PropertyValueInterceptor` that
  restricts the range of values a numeric property can have, applies
  "resistance" when the value is overshooting, and provides the ability to
  animate it back within range. It's particularly useful in combination with
  `WheelHandler`, to provide similar physics as Flickable has.

- `Image` and `BorderImage` now have the same `currentFrame` and `frameCount`
  properties that `AnimatedImage` has; this allows choosing an individual icon
  from an .ICO file that contains multiple icons, for example.
  In the future it's intended to support other multi-page formats such as
  PDF, TIFF and WEBP.
