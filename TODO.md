# TODO

- "exception during sync" aren't caught

## Media

- nio ClientTimeout

- Handle upload file size limit
- Handle set avatar upload errors
- Confirmation box after picking file to upload
- Show real progression for mxc thumbnail loadings

- Sentinel function to report download file path if already cached,
  without having to click & try downloading first
- EventFile download UI & Save as... in context menu

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
- Prevent using upload keybinds in rooms with no perms

## Refactoring

- Account settings with `HTabbedContainer`
  - Get rid of all `currentSpacing` stuff
  - Use new default/reset controls system 
- Split `HScrollableTextArea`
- Composer
- Don't put all the keybinds in one central file
  - Missing room keybinds (invite, etc) and close failed upload
- Use QML states?

## Issues

- Forget a room, it comes back because of the "you left" event
- `EventImage`s for `m.image` sometimes appear broken, can be made normal
  by switching to another room and coming back
- First sent message in E2E room is sometimes undecryptable

- Pausing uploads doesn't work well, servers end up dropping the connection 

- In the "Leave me" room, "join > Hi > left" aren't combined
- When selecting text and scrolling up, selection stops working after a while
  - Ensure all the text that should be copied is copied
  - Multiple messages are currently copied out of order

- Pressing backspace in composer sometimes doesn't work

- `code` not colored in room subtitle
- Quote links color in room subtitles (e.g. "> http://foo.orgA)" )

- If account not in config anymore, discard ui state last page on startup
- Do something when access token is invalid

- Don't store states in delegates
- [hr not working](https://bugreports.qt.io/browse/QTBUG-74342)
- Terrible performance using `QT_QPA_PLATFORM=wayland-egl`, must use `xcb`
- Can't use `QQmlApplicationEngine`, problem with QApplication?
  See https://bugreports.qt.io/browse/QTBUG-50992

## Interface

- Room Sidepane keybinds
- Remember ctrl+tab page target
- https://doc.qt.io/qt-5/qml-qtquick-smoothedanimation.html for progress bars
- Make all "Cancel" buttons able to cancel running Backend coroutines set
  `disabledWhileLoading` to `false` for all "OK" buttons where it makes sense
- Use a loader of the swipeview containing members, settings, etc views
- Expand the room pane if it's too small to show room settings?
- Drop the `buttonModel`/`buttonCallbacks` HBox approach
- Scrollable popups and room settings
- Improve when HDrawer should collapse when the ui is zoomed
- Make theme error/etc text colors more like name colors
- In account settings, display name field text should be colored
- Way to open context menus without a right mouse button
- `smartVerticalFlick()` gradual acceleration
- Make banner buttons look better
- When window is reduced enough for main pane to be invisible, transition
  between pane and page with alt+S is laggy when the page is a chat

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

- Streaming download & decrypt
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

## Distribution & dependencies

- Mistune v2.0
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

### [Qt 5.15](https://wiki.qt.io/New_Features_in_Qt_5.15)

- Introduced inline components
  (ability to declare multiple QML components in the same file)

- Introduced `required` properties

- Added a declarative way of registering types to QML

- Added support for the Nullish Coalescing Operator (`??`)

- Added `qmlformat` tool which automatically formats any QML file according to
  the QML Coding Conventions.

- Added `cursorShape` property to pointer handlers. Most pointer handlers
  (e.g. `DragHandler`) will change the cursor when the active state is true.
  `HoverHandler` will change it when the mouse is hovering over the `Item` that
  contains the `HoverHandler`.
