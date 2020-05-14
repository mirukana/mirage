# TODO

- revise pane collapse mode

- fix python getting stuck when loading large room
- fix accounts in room list not getting their profile updated if mirage starts
  with a filter

- account delegates refactor
- lag when switching accounts
- update glass theme

- if last room event is a membership change, it won't be visible in timeline
- use uiState instead of open_room
- clicking on a room with unread counter to see it move right away is weird
- rooms without messages on first sync
- avatar loading performance problem?

- docstrings

## Refactoring

- Rewrite account settings using `HTabbedContainer`
  - Get rid of all `currentSpacing` stuff
  - Use new default/reset controls system 
  - Display name field text should be colored 

- Split `HScrollableTextArea` into `HTextArea` and `HScrollView` components
- Refactor `Composer`

- Drop the `HBox` `buttonModel`/`buttonCallbacks` `HBox` approach,
  be more declarative

## Issues

- Drag-scrolling in room pane a tiny bit activates the delegates

- Catch server 5xx errors when sending message and retry 

- Popups and room settings can't be scrolled when not enough height to show all

- Handle cases where a known account's access token is invalid
- If an account is gone from the user's config, discard UI state last page

- After forgetting a room, it comes back because of the "you left" event

- `code` and links in quote ("> http://example.com") aren't properly colored
  in room "last message" subtitle

- `Timer` and `Animation` are bound to framerate
- Can't use `QQmlApplicationEngine`, problem with QApplication?
  See https://bugreports.qt.io/browse/QTBUG-50992
- [HTML <hr> not rendered](https://bugreports.qt.io/browse/QTBUG-74342)
- Pausing uploads doesn't work well, servers ends up dropping the connection 
  (no real solution possible?)

## Interface

- Long-press-drag to select multiple messages on touch
- Drag to select multiple messages on non-touch

- Make clicking on user/room mentions open relevant UI instead of matrix.to
  URL in browser
- Make rooms fully manageable within Mirage: settings, permissions, unban

- Labeled text area component, use it for room creation/settings topic 
  - Linkify URLs in topic text areas

- Expand the room pane if it's currently too small to show room settings
- Use a loader for items not in view for the `HTabContainer`'s `SwipeView`

- Make "Cancel" buttons consistent, and able to cancel running Backend
  coroutines. Set `disabledWhileLoading` to `false` for all "OK" buttons where
  it makes sense.

- Remember the previously focused item in page for ctrl+tab 
- https://doc.qt.io/qt-5/qml-qtquick-smoothedanimation.html for progress bars
- Improve when HDrawer should collapse when the ui is zoomed
- Make room invite/left banner buttons look better

- Choose a better easing types for animations
- Make HListView scrollbars more visible
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
- Replies
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

- Server selection
- Implement Register/Reset pages

- Theming
  - Use a standard file format
  - icons.preferredPack: accept multiple values
  - Find icon packs in user data dir
  - See [Text.fontSizeMode](https://doc.qt.io/qt-5/qml-qtquick-text.html#fontSizeMode-prop)

- Settings page
- Notifications
- Opening links with keyboard
- Better `<pre>` 

- Replace the rubbish default filepicker on Linux

## Media-related

- UI for download progress (using `Transfer` like for uploads)

- Add upload keybindings (close failed upload, pause, resume)
- Handle errors when setting an avatar
- Show confirmation box when picking file to upload or uploading from clipboard
- Show proper progress ring for mxc thumbnails loading

- Sentinel function to report local file paths for already downloaded media,
  without having to click and try downloading first
- EventFile "Save as..." context menu entry

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

- Saving the room settings
- Refetch profile after manual profile change, don't wait for a room event

- Better config file format

- Prevent starting multiple client instances, causes problems with E2E DB
- Check if username exists on login screen
- [Soft logouts](https://github.com/poljar/matrix-nio/commit/aba10)
- Logout previous session when adding an account that's already connected

- Startup improvements:
  - Initial sync filter to get more events on first sync
  - Lazy loading members
  - Cache and restore profiles, room events and states
  - Use AsyncClient `store_sync_tokens`
    - Make sure to all members are fetched before sending an E2E message 
    - Fetch all members when using the filter members bar

- Properly handle direct chats 
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

- Left room events after client reboot
- Previewing room without joining

- Add the `resume()` account "login" method

## Distribution and dependencies

- Add AppImage metadata file
- Pillow now bundle image libraries?
  Update AppImage building script and INSTALL.md
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
