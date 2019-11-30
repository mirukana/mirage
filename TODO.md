- Media
  - Verify things work with chat.privacytools.io (subdomain weirdness)
  - Confirmation box after picking file to upload
  - Handle upload/set avatar errors: bad path, is a dir, file too big, etc
  - Show real progression for mxc thumbnail loadings, uploads and downloads

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

  - Create room tabs brutal size transition

- Refactoring
  - Use `.pragma library` for utils.js
  - Room header elide detection
  - Use HBox for Profile
  - Banners
  - Composer

  - Room Sidepane
    - Hide when window too small
    - Also save/load its size
    - Is auto-sizing actually needed, or can we just set a default manual size?
    - Reducable room sidepane, swipe to show full-window

- Fixes
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
  - Left rooms reappear as joined rooms

  - If account not in config anymore, discard ui state last page on startup
  - Do something when access token is invalid

  - Don't store states in delegates
  - [hr not working](https://bugreports.qt.io/browse/QTBUG-74342)
  - Terrible performance using `QT_QPA_PLATFORM=wayland-egl`, must use `xcb`
  - Quote links color in room subtitles (e.g. "> http://foo.orgA)" )

- UI
  - Way to open context menus without a right mouse button
  - `smartVerticalFlick()` gradual acceleration

  - Just use Shortcut onHeld instead of analyzing the current velocity
    in `smartVerticalFlick()`
  - Thinner expand arrow icon
  - Restore previous focus after closing right click context menu
  - Choose a better default easing type for animations
  - Make HListView scrollbars visible
  - Remove first html lists left margin
  - Adapt UI for small heights

  - In room creation, click avatar to set the future room's avatar
  - In join room page, show the matching room's avatar when typing
  - In find someone page, show the matching user's avatar when typing

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
    - After combining is implemented, no need to hide profile changes anymore.
  - Replies
  - Messages editing and redaction
  - Code highlighting
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

  - Add stuff to room tooltips like last messages
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
  - Prevent using the composer if no permission (power levels)
    - Prevent using an alias if that user is not in the room or no permission
  - Spinner when loading past room events

  - Theming
    - Bundle fonts
    - Standard file format, see *~ppy/qml_dict_theme.qml*
    - https://doc.qt.io/qt-5/qtquickcontrols2-customize.html#creating-a-custom-style
    - icons.preferredPack: accept multiple values
    - Find icon packs in user data dir
    - Correctly implement uiScale/fontScale + ctrl+-= keys
      - See `QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling)`
      - See [Text.fontSizeMode](https://doc.qt.io/qt-5/qml-qtquick-text.html#fontSizeMode-prop)
    - Way to round avatar corners to allow box radius
    - If avatar is set, name color from average color?
    - Accent color from background

  - Settings page
  - Notifications
  - Opening links with keyboard
  - Better `<pre>` 

  - Custom file picker for Linux (...)

- Major features
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

- Client improvements
  - Refetch profile after manual profile change, don't wait for a room event

  - Prevent starting multiple instances, causes problems with E2E DB
    (sending new messages from second instances makes them undecryptable to
     first instance until it's restarted)
    - Could be fixed by "listening for a `RoomKeyEvent`that has the same
      session id as the undecryptable `MegolmEvent`, then retry decrypting
      the message with `decrypt_event()`"  - poljar

  - [Soft logouts](https://github.com/poljar/matrix-nio/commit/aba10)
  - Check if username exists on login screen
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
    it should be the peer's display name instead.
  - Animate RoomEventDelegate DayBreak apparition
  - Live-reloading accounts.json

- nio
  - Running blocking DB function calls in executor
  - `AsyncClient.share_group_session`: send device batches concurrently

  - RoomMessageMedia and RoomAvatarEvent info attributes
  - `m.room.aliases` events
  - MatrixRoom invited members list
    - When inviting someone to direct chat, room is "Empty room" until accepted,
  - Left room events after client reboot
  - `org.matrix.room.preview_urls` events
  - Support "Empty room (was ...)" after peer left
  - Previewing room without joining

  - Get content repo config API
  - Add the `resume()` method

  - See if we can turn all the Error classes into actual exceptions

- Distribution
  - Include python dependencies in binary with rcc?
  - README.md
