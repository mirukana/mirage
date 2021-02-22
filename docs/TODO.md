# TODO

- push popup cancel & remove
- right click on rule
- combo box custom item
- explain pattern
- fix spinbox buttons
- way to add new rule 
- quick room & sender rule changes
- config & keybind for global rule disabling
- quick settings
- import/export/json edit rules?
- add missing license headers to qml files
- fix flickable popups can't be flicked by keyboard
- room selector for room rules
- validate json for unknown action/condition
- seen tooltips can't be shown on image hover

- PCN docstrings 
- PCN error handling
- Change docs linking to dev branch back to master 

- Implement fallback QML notifications, usable if dbus isn't available
- profiles missing in notifications
- option to use plaintext notifications
- Notification urgency level (plyer)?
- annoying tooltips when menu open

- add http_proxy support
- image viewer: can't expand image in reduced window layout
- Encrypted rooms don't show invites in member list after Mirage restart
- Room display name not updated when someone removes theirs
- Fix right margin of own `<image url>\n<image url>` messages
- warn on ambiguously activated shortcut

- SSO device delete?
- filter > enter > room list is always scrolled to top
- refresh server list button

- global presence control

- publish room or alias control

- open context menus centered on touch screens 
- auto-idle for Windows and OSX 
- status based on process detection

## Refactoring

- General change/upload avatar component for account and room settings
- Refactor EventList.qml
- Refactor `InviteBanner`/`LeftBanner`
- Implement different delegate for different types of events in QML, instead
  of having only one doing everything with untranslatable content texts
  from Python

## Issues

- Show a proper error when accepting a room invite that has expired or
  the room doesn't exist anymore (`MatrixNotFound`)

- Replying to one of our own message that's currently only a local echo
  results in a reply to an empty ID

- Bottom focus line for an `HTextArea` inside a `ScrollView` is invisible,
  put the background on `ScrollView` instead?

- Don't send typing notification when switching to a room where the composer 
  has preloaded text 

- When calling `Backend.update_room_read_marker()` for a recent message,
  the marker will only be updated for accounts that have already received
  it (server lag) 

- Jumping between accounts (clicking in account bar or alt+(Shift+)N) is
  laggy with hundreds of rooms in between

- Drag-scrolling in room pane a tiny bit activates the delegates

- Catch server 5xx errors when sending message and retry 

- After forgetting a room, it comes back because of the "you left" event

- `code`, mentions and links in quote ("> http://example.com") aren't properly
  colored in room delegate "last message" subtitle

- `Timer` and `Animation` are bound to framerate
- Can't use `QQmlApplicationEngine`, problem with QApplication?
  See https://bugreports.qt.io/browse/QTBUG-50992
- [HTML <hr> not rendered](https://bugreports.qt.io/browse/QTBUG-74342)
- Pausing uploads doesn't work well, servers ends up dropping the connection 
  (no real solution possible?)

## Interface

- Colorize "@room" in messages
- Device IP geolocation
- Can rooms be left with a reason?

- When responding to a message, highlight that message in the timeline
- Highlight timeline messages that mentions our user
- Add room members loading indicator, similar to the "Loading past messages..."

- Long-press-drag to select multiple messages on touch
- Drag to select multiple messages on non-touch

- Make clicking on user/room mentions open relevant UI instead of matrix.to
  URL in browser

- Missing room settings:
  - Set whether to publish this room in the server room directory
  - Set history visibility
  - Set aliases 
  - Setup permissions 
  - Unban members
  - Set flair (which community this room belongs to)

- Linkify URLs in topic text areas

- Use a loader for items not in view for the `HTabContainer`'s `SwipeView`

- Make "Cancel" buttons consistent, and able to cancel running Backend
  coroutines. Set `disabledWhileLoading` to `false` for all "OK" buttons where
  it makes sense.

- Remember the previously focused item in page for ctrl+tab 
- https://doc.qt.io/qt-5/qml-qtquick-smoothedanimation.html for progress bars
- Improve when HDrawer should collapse when the ui is zoomed
- Make room invite/left banner buttons look better

- Choose a better easing types for animations
- In messages, remove the HTML lists excess left margin
- Improve UI for very small window heights

- In room creation, click avatar to set the future room's avatar
- In join room page, show the matching room's avatar when typing
- In direct chat page, show the matching user's avatar when typing

- Combine events so they take less space
  - After combining is implemented,
    no need to hide profile changes by default anymore

- Animate `DayBreak` apparition

- Device settings
- Proparly formatted rich replies
- Messages editing
- Code highlighting
- Adapt shortcuts flicking speed to font size 

- Accept drag and drop to upload files or set a new avatar 
- Improve room tooltips, e.g. show last messages
- Warn user when connection is lost or 429s happen
- "Rejoin" LeftBanner button if room is public
- Daybreak color
- Conversation breaks: show time of first new msg after break instead of big
  blank space

- `MainPane`:
  - Animate when logging out last account and sidepane turns invisible

- Implement Register/Reset pages

- Theming
  - Use a standard file format
  - icons.preferredPack: accept multiple values
  - Find icon packs in user data dir
  - See [Text.fontSizeMode](https://doc.qt.io/qt-5/qml-qtquick-text.html#fontSizeMode-prop)

- Settings page
- Notifications
- Better `<pre>` 

- Replace the rubbish default Qt filepicker on Linux

## Media-related

- UI for download progress (using `Transfer` like for uploads)

- Add upload keybindings (close failed upload, pause, resume)
- Handle errors when setting an avatar

- Show a reason or HTTP error code for thumbnails that fail to load
- Support `m.file` thumbnails

- Generate video thumbnails
- Display GIF static thumbnails while the real GIF is loading
- Audio/video player
  - Can GIFs use it?

- `EventLink` for client-side URL previews
  - Special UI for matrix.to URLs

- Prevent using upload keybindings in rooms where user doesn't have permission
  to upload

## Backend

- Better config file format

- Prevent starting multiple client instances, causes problems with E2E DB
- Check if username exists on login screen
- [Soft logouts](https://github.com/poljar/matrix-nio/commit/aba10)

- Cache and restore profiles, room events and client states

- Properly handle direct chats 
- Live-reloading accounts.json

- E2E
  - SAS verification
  - Request room keys from own other devices
  - Provide help when undecryptable messages occur, including:
    - Trigger `nio.AsyncClient.request_room_key`
    - Option to export-logout-login-import to fix one-time key problems
  - Cross-signing

- Fully read markers

- Methods of signing in that aren't handled yet:
  - `m.login.password` alternate logins methods:
    - `m.id.thirdparty`
    - `m.id.phone`
  - `m.login.recaptcha` (need browser, just use fallback?)
  - `m.login.email.identity`
  - `m.login.msisdn` (phone)
  - `m.login.dummy`
  - Web page fallback

## Nio contributions

- Streaming download & decrypt
- Running blocking DB function calls in executor (WIP)

- Dedicated error for invalid password on key import
- `RoomMessageMedia` and `RoomAvatarEvent` info attributes
- Handle `m.room.aliases` events

- Left room events after client reboot
- Previewing room without joining

## Distribution and dependencies

- Use Qt 5.14 for AppImage
- Add AppImage & Flatpak metadata file
- Publish on Flathub and AppImageHub

- Update to Mistune v2.0 when released

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
  - Rewrite `HKineticScrollingDisabler` with it 

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

- `Binding.restoreMode`: This property can be used to describe if and how the
  original value should be restored when the binding is disabled.

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

- Added `selectTextByMouse` property to `ComboBox`.

- Technology Preview: Support for running Qt Quick (2D) on top of 
  Direct3D, Metal and Vulkan

- `ListView.reuseItems` property
