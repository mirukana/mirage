- Refactoring
  - Banners
  - Composer

  - Room Sidepane
    - Hide when window too small
    - Also save/load its size
    - Is auto-sizing actually needed, or can we just set a default manual size?
    - Reducable room sidepane, swipe to show full-window

  - When qml syntax highlighting supports ES6 string interpolation, use them

- Fixes
  - Make uvloop optional
  - Backspace bug

  - Show error if uploading avatar fails or file is corrupted

  - If account not in config anymore, discard ui state last page on startup
  - Don't strip user spacing in html
  - Do something when access token is invalid
  - Keyboard flicking against top/bottom edge

  - Message position after daybreak delegate  (fixed by commit 57b1313 ?)
  - [hr not working](https://bugreports.qt.io/browse/QTBUG-74342)
  - Terrible performance using `QT_QPA_PLATFORM=wayland-egl`, must use `xcb`

- UI
  - Just use Shortcut onHeld instead of analyzing the current velocity
    in `smartVerticalFlick()`
  - Reduce icons brightness
    - Thinner expand arrow
  - Restore previous focus after closing right click context menu
  - Choose a better default easing type for animations
  - Make HListView scrollbars visible
  - Remove first html lists left margin
  - Adapt UI for small heights

  - Inviting members to a room
    - Make invite icon blink if there's no one but ourself in the room,
      but never do it again once the user hovered it long enough to show 
      tooltip or clicked on it once 

  - Restoring UI state:
    - Composer content
    - Which element was focused
    - Room member filter field

  - Prevent others from having a too similar hue as us, or our own accounts
    from sharing a too similar hue
  - Combine events so they take less space
    - After combining is implemented, no need to hide our own profile changes.
  - Replies
  - Messages editing
  - Code highlighting
  - Support GIF avatars
  - Adapt shortcuts flicking speed to font size and DPI

  - EditAccount page:
    - Device settings
    - Multiaccount aliases:
      - Warn when conflict with another alias
      - Forbid spaces?
      - Add an explanation tooltip
      - Prevent sending messages with an user not in room
      - Support \ escaping
    - Accept drag and dropping a picture to set avatar

  - Improve avatar tooltips position, add stuff to room tooltips (last msg?)
  - Show something when connection is lost or 429s happen
  - "Rejoin" LeftBanner button if room is public
  - Daybreak color
  - Conversation breaks: show time of first new msg after break instead of big
    blank space

  - Sidepane
    - Animate when logging out last account and sidepane turns invisible
    - Header back button when reduced
    - Better look for arrows and option button when collapsed
    - Show it when hovering/hitting focus keybind on the left when collapsed
    - Ability to drag on any place of the pane to resize

  - Server selection
  - Register/Forgot? for SignIn dialog
  - Add room
  - Logout & leave/forget room warning popup
  - Prevent using the composer if no permission (power levels)
    - Prevent using an alias if that user is not in the room or no permission
  - Spinner when loading past room events or images 

  - Theming
    - Bundle fonts
    - File format
    - icons.preferredPack: accept multiple values
    - Find icon packs in user data dir
    - Correctly implement uiScale/fontScale + ctrl+-= keys
      - See `QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling)`
      - See [Text.fontSizeMode](https://doc.qt.io/qt-5/qml-qtquick-text.html#fontSizeMode-prop)
    - Way to round avatar corners to allow box radius
    - If avatar is set, name color from average color?
    - Accent color from background

  - Settings page
  - Message/text selection
  - Notifications

  - Custom file picker for Linux...

- Major features
  - E2E
    - Device verification
    - Edit/delete own devices
    - Request room keys from own other devices
    - Auto-trust accounts within the same client
    - Export keys
  - Uploads & proper http thumbnails
    - Reduce messages ListView cacheBuffer height once http thumbnails
      downloading is implemented 
  - Read receipts
  - Status message and presence
  - Links preview

- Client improvements
  - Prevent starting multiple instances, causes problems with E2E DB
    (sending new messages from second instances makes them undecryptable to
     first instance until it's restarted)
  - `translated` arg for avatar upload and login errors
  - Check if username exists on login screen
  - `pyotherside.atexit()`
  - Logout previous session if adding an account that's already connected
  - Image provider: on failed conversion, way to show a "broken image" thumb?
  - Config file format
  - Initial sync filter and lazy load, see weechat-matrix `_handle_login()`
    - See also `handle_response()`'s `keys_query` request
  - Direct chats category
  - Markdown: don't turn #things (no space) and `thing\n---` into title,
    disable `__` syntax for bold/italic
  - `<pre>` scrollbar on overflow
  - When inviting someone to direct chat, room is "Empty room" until accepted,
    it should be the peer's display name instead.
  - Animate RoomEventDelegate DayBreak apparition
  - Room subtitle: show things like "*Image*" instead of blank, etc
  - Live-reloading accounts.json

- nio
  - `AsyncClient.share_group_session`: send device batches concurrently

  - downloads API
  - MatrixRoom invited members list
  - Invite events are missing their timestamps (needed for sorting)
  - Left room events after client reboot
  - `org.matrix.room.preview_urls` event
  - `m.room.aliases` event
  - Support "Empty room (was ...)" after peer left
  - Previewing room without joining

- Distribution
  - Include python dependencies in binary with rcc?
  - README.md
