- Refactoring
  - Make all icon SVG files white/black, since we can now use ColorOverlay
    - Make the icon blue in EditAccount when hovering and no avatar set

  - Use HInterfaceBox for EditAccount Profile and Encryption 
  - HButton
    - Control: hovered, visualFocus, enaled
    - Border and pressed color in theme / checkbox theming

  - `^property type name$`
  - Use [Animators](https://doc.qt.io/qt-5/qml-qtquick-animator.html)
    - Choose a better default easing type for animations
  - Sendbox
  - Room Sidepane
    - Hide when window too small
    - Also save/load its size
  - When qml syntax highlighting supports ES6 string interpolation, use them

- Fixes
  - (Left?)Banner binding loop
  - Reloading config files (cache)
  - Tiny invisible scrollbar
  - Run import in thread and AsyncClient.olm functions, they block async loop
  - Handle import keys errors

  - Don't linkify images for outgoing html
  - Message position after daybreak delegate
  - Keyboard flicking against top/bottom edge
  - Don't strip user spacing in html

  - Do something when access token is invalid
  - [hr not working](https://bugreports.qt.io/browse/QTBUG-74342)
  - Terrible performance using `QT_QPA_PLATFORM=wayland-egl`, must use `xcb`

- UI
  - Popup:
      - label size
      - Accept/cancel buttons
      - Transitions

  - Restoring UI state:
    - Sendbox content
    - Which element was focused
    - Room member filter field

  - Combine events so they take less space
    - After combining is implemented, no need to hide our own profile changes.
  - When starting a long task, e.g. importing keys, quitting the page,
    and coming back, show the buttons as still loading until operation is done
  - Make invite/left banners look better in column mode
  - Responses
  - Messages editing
  - Code highlighting
  - Support GIF avatars
  - When reduced, show the full-window sidepane instead of Default page
  - Adapt shortcuts flicking speed to font size and DPI
  - Show error box if uploading avatar fails
  - EditAccount page:
    - Remove account from client
      - state: Set UI state page to Default.qml when account is removed
    - Device settings
    - Multiaccount aliases:
      - Warn when conflict with another alias
      - Forbid spaces?
      - Add an explanation tooltip
      - Prevent sending messages with an user not in room
      - Support \ escaping
  - Improve avatar tooltips position, add stuff to room tooltips (last msg?)
  - Accept drag and dropping a picture in account settings to set avatar

  - Show something when connection is lost or 429s happen
  - "Rejoin" LeftBanner button if room is public
  - Daybreak color
  - Conversation breaks: show time of first new msg after break instead of big
    blank space
  - Replies
  - `pyotherside.atexit()`
  - Sidepane
    - Header back button when reduced
    - Better look for arrows and option button when collapsed
    - Way to put it back to auto-sizing (snap)
    - Show it when hovering on the left when collapsed/reduced
    - Ability to drag on any place of the pane to resize
  - Reducable room sidepane, swipe to show full-window

  - Invite to room
  - Server selection
  - Register/Forgot? for SignIn dialog
  - Add room
  - Leave room
  - Forget room warning popup
  - Prevent using the SendBox if no permission (power levels)
    - Prevent using an alias if that user is not in the room or no permission
  - Spinner when loading account, past room events, images or clicking buttons
    - Show account page as loading until profile initially retrieved
  - Theming
    - Don't create additional lines in theme conversion (braces)
    - Recursively merge default and user theme
    - Distribute fonts
    - preferredIconPack: accept multiple values
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
    - Import/export keys
  - Uploads & proper http thumbnails
    - Reduce messages ListView cacheBuffer height once http thumbnails
      downloading is implemented 
  - Read receipts
  - Status message and presence
  - Links preview

- Client improvements
  - Logout previous session if adding an account that's already connected
  - Image provider: on failed conversion, way to show a "broken image" thumb?
  - Config file format
  - Initial sync filter and lazy load, see weechat-matrix `_handle_login()`
    - See also `handle_response()`'s `keys_query` request
  - Direct chats category
  - Markdown: don't turn #things (no space) and `thing\n---` into title,
    disable `__` syntax for bold/italic
  - Push instead of replacing in stack view (remove getMemberFilter when done)
  - `<pre>` scrollbar on overflow
  - When inviting someone to direct chat, room is "Empty room" until accepted,
    it should be the peer's display name instead.
  - Animate RoomEventDelegate DayBreak apparition
  - Room subtitle: show things like "*Image*" instead of blank, etc

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
