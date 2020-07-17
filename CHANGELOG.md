# Changelog

All notable changes will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## 0.6.0 (2020-07-17) 

### Added

- **Room member profiles**:
  - Can be accessed by clicking on a user in the room's right pane, or focusing
    the filter field and navigating with up/down/enter/escape

  - Includes large avatar, display name, user ID, **presence** info,
    **power level control** and **E2E sessions list**

- **E2E Verification**:
  - Sessions for room members can now be (manually) verified from
    their profile

  - Sessions for different accounts within the same client will automatically
    verify each others based on session keys

  - Verifying a session will automatically verify it for all connected accounts,
    as long as the session keys are identical

- **Presence**:
  - Added presence (online, unavailable, invisible, offline) and status
    message control to the accounts context menu in the room list

  - Added `togglePresence{Unavailable,Invisible,Offline}` keybinds bound by 
    default to `Ctrl+Alt+{A/U,I,O}`

  - Added `openPresenceMenu` keybind to open the current account's context
    menu, `Alt+P` by default

  - The room member list is now sorted by power level, then presence, then name

  - The room member list will display presence orbs and last seen time for
    members if the server supports it. Last seen times for offline members
    are also automatically retrieved as needed.

  - Set logged in accounts offline when closing Mirage

  - Linux/X11 specific: Add auto-away feature configurable by the
    `beUnavailableAfterSecondsIdle` setting (default 600 for 10mn),
    can be disabled by setting it to `-1`.  
    **This requires the libX11 and libXScrnSaver/libXss developpment headers
    installed, see INSTALL.md for more info**.  
    The dependencies and support for this feature can be disabled at
    compile-time.

- **Session sign out**: you can now sign out your other sessions from the 
  account settings. This currently only supports password authentification.

- **Pasting images** via Ctrl+V or composer context menu, shows a preview of
  the image before uploading

- Added basic keyboard navigation for account settings session list:
  - Up/down: highlight previous/next session
  - Enter/Return/Menu: open highlighted session menu
  - Space: check or uncheck highlighted sessions
  - Escape: uncheck all sessions
  - Alt+R/F5: refresh list
  - Alt+S/Delete: sign out checked sessions, or all sessions if none checked

- Add a verified devices indicator to encrypted room headers

- Add experimental support for rendering of inline images and custom emotes in
  messages

- Add `kineticScrollingMaxSpeed` and `kineticScrollingDeceleration` settings

- When highlighting accounts, rooms or members in lists 
  (focus filter field and use up/down), the highlighted item's context menu
  can now be accessed with the keyboard Menu key

- Support for Menu key when keyboard-navigating messages in the timeline

- Add context menus to text field and areas

- Add a button to quickly expand the room pane when collapsed and focus
  the filter field

- Clicking on the current tab button for the room pane now fully hides it,
  this can also be toggled with the new `toggleHideRoomPane` keybind 
  (default Ctrl+Alt+R)

- Themes:
  - Add the `controls.presence` section
  - Add `mainPane.listView.offlineOpacity` property
  - Add CSS styling for `table` and `td` in the `chat.message.styleSheet`
    property

### Changed

- When panes are smaller than their default width due to user resizing or
  window size constraints, focusing certain elements will auto-expand them
  until the focus is lost: filter fields, member profile and room settings

- Reduced the default kinetic scrolling speed, which was hardcoded to an
  aggressive `4000` before.
  This can be restored with the `kineticScrollingMaxSpeed` setting.

- Improve key verification popup texts and make the session details copiable

- Power levels/room permission change events will now show a line of text or
  table containing the details of what exactly changed 

- Messages containing tables will no longer be width-limited

- Using the `sendFileFromPathInClipboard` keybind (default Alt+Shift+S)
  now shows a preview of the file if it's an image and asks for confirmation

- Image messages now show spinners when loading the thumbnail

- Clicking on a GIF message will now open it externally like other images
  instead of pausing it. A dedicated play/pause button is now displayed in 
  the corner.

- Themes: 
  - Update the `colors.positiveBackground`, `colors.middleBackground` and
    `colors.negativeBackground` properties to be brighter and have full opacity

  - Increase the opacity for the `menu.background` color (context menu), the
    previous value made it very hard to read in certain situations

### Removed

- Themes: removed the `image` section and its `maxPauseIndicatorSize` property,
  no longer used since the GIF changes

### Fixed

- Fix parsing user/room ID and room aliases containing dashes in messages

- Fix responding to own messages sending an incorrect event ID to other clients

- Fix plain text body of replies sent from Mirage

- Fix high CPU usage due to the "Loading messages..." animation still being
  rendered when invisible

- When logging in to an already connected account, redirect to the account
  settings page instead of overwriting it and losing the previous session

- Fix signing out of an account leaving all its room in the room list

- Fix all keybinds becoming disabled until next restart if a popup or menu
  is destroyed instead of being properly closed 

- Fix pressing left/right arrow to deselect text in fields and areas when the
  cursor is positioned at the beginning/end 

- Fix missing text for events involving display names that contain `< >`
  characters and other dangerous characters interpreted by HTML

- Fix sending a typing notice indicating we stopped typing when the composer
  is cleared (e.g. when erasing all text or sending a message)

- Fix hovering image messages not setting the pointing hand cursor

- Opening a context menu and clicking at the exact spot where it was opened 
  without having moved the cursor will now close the menu instead of doing
  nothing

- Highlight the correct room list item when adding a new account, going
  to account settings or ctrl+tabbing to the "add new chat" page

- Fix right room pane being shown as overlay sometimes in small window mode 

- Fix avatar membership icon (crown/star) position when the room pane is small

- Correctly handle SIGINT (ctrl+c in terminal), SIGTERM, SIGHUP and SIGQUIT
  to exit Mirage

- Fix opacity of topic area in room settings when disabled due to lack of 
  permission

- Fix GIF only having a cropped portion of their content rendered

- Hide the "recursive layout" warnings spam in terminal that appeared
  in Qt 5.14


## 0.5.2 (2020-06-26)

### Added

- **Sessions/device list**: you can now inspect, rename, manually verify and
  blacklist your devices from the account settings page.
  The interface is still work in progress, keyboard navigation and signing
  out sessions will be added in a next version.

- Re-add client-side unread/highlight room indicators.
  If your account has push notifications disabled, which precise cross-client
  counters depend on, the local indicators will be used as fallback.

- Support the `MIRAGE_CACHE_DIR` environment variable to override where
  files and thumbnails are downloaded

- Themes:
  - `colors.positiveText` property
  - `mainPane.listView.room.unreadName` property
  - In the `controls` section:
    - `scrollBar` section
    - `button.focusedBorder` and `button.focusedBorderWidth` properties
    - `tab.focusedBorder` and `tab.focusedBorderWidth` properties
    - `textArea.borderWidth`, `textArea.border`, `textArea.focusedBorder` and
      `textArea.errorBorder` properties

### Changed

- Overhauled account settings to match the design of other tabbed pages.
  The horizontal layout design has been removed due to complicated code and 
  being impossible to extend without breaking it.

- The display name field in account settings is now colored, 
  preview your new display name's color as you type

- For rooms without image avatars set, the room settings's avatar color now
  responds to the name field as you type

- Overhauled scrollbars:
  - Now match the Mirage theme and much better visibility
  - No more right margin for the timeline's bar
  - Minimum height to prevent the bar from becoming impossible to grab

- Use brighter text for room names of rooms that have unread messages

- Buttons, tabs, text fields and areas now have animated bottom borders 
  to represent keyboard focus instead of being highlighted like when hovered

- Text fields and areas can now have rounded corners, following the theme

- Tabbed pages (Sign In, Add Chat, etc) can now be swiped left and right

- Popups can now be scrolled when their content is bigger than the
  window's height

- Replace most generic checkmark icons for apply buttons in popups

- Pressing escape in forms will consistently trigger corresponding
  cancel buttons

### Fixed

- Fix `Connections` deprecation warning on Qt 5.15

- Skip invisible entries when navigating context menus with up/down arrows

- Fix tab focus for unhandled error and invite to room popups

- Fix guest access event saying that guest access has been allowed when it 
  has actually been forbidden

- Deselect any selected message before clearing a room's events, not doing so
  made the gone messages impossible to deselect.

- Properly center some previously offset popups


## 0.5.1 (2020-06-05)

### Added

- **Saving room settings**: room name, topic, guest access, invite requirement,
  guest access and encryption can now be changed and saved from the room's 
  settings pane 

- `markRoomReadMsecDelay` setting to configure how long in milliseconds Mirage
  will wait before marking a focused room as read, defaults to `200`

- `alertOnMentionForMsec` setting separate from `alertOnMessageForMsec`,
  defaulting to `-1`: will trigger a non-expiring window highlight on
  messages received that mention your user
  (the behavior differs depending on desktop environment or window manager)

### Changed

- **Unread message/highlight counters**:
  - The counters are now implemented in a cross-client, persistent way,
    and respect configured push rules for your account
  - Read receipts will be sent to the server to mark rooms as read

- The `alertOnMessageForMsec` setting now defaults to `0`, disabling window
  highlights for messages not mentioning you

- While an E2E key import operation is running, prevent accidentally closing
  the popup by clicking outside of it

- For manual installations, `make install` will now copy files to `/usr/local`
  instead of `/usr` by default.
  This can be changed by setting `PREFIX` when running `qmake`,
  e.g. `qmake PREFIX=/usr`.
  After pulling the latest version, make sure to clean up old installation
  and build files before regenerating the Makefile and installing:
  `sudo make uninstall; make clean; qmake && make && sudo make install`

- Improve the error messages shown when trying to start a direct chat with or 
  invite a non-existing user

- In room settings or creation, use a text area for the topic instead of a
  field limited to a single line 

### Removed

- Removed delay when multiple rooms are removed/hidden from the list.
  This should provide a smoother experience when filtering rooms or collapsing
  accounts, and prevent the account duplication bug.
  If you encounter issues with these operations like the room list becoming
  invisible, make sure first that your Qt installation is up-to-date
  (latest x.y.Z version, e.g. 5.14.2).

### Fixed

- The room settings pane is now scrollable

- Avoid potential error if the room list data model is initialized after an
  initial sync has already been completed

- Closing the import key popup by pressing escape will now correctly
  cancel any running import operation

- Fix Python pickling error when trying to re-decrypt events after importing
  E2E keys ([#50](https://github.com/mirukana/mirage/issues/50))

- Handle Matrix 502 errors returned when trying to start a direct chat or 
  invite a user with an incorrect or unresponsive server in their ID

- Correctly hide `socket.gaierror` error popups that appear when the
  internet connection drops

- Hide popups for pointless
  `ssl.SSLError: [SSL: KRB5_S_INIT] application data after close notify`
  exceptions that occur in the Flatpak releases due to a Python 3.7 bug

- Make sure the account shown in the left pane is immediately updated 
  after changing display name or avatar in the account settings

- When signing in a new account, correctly position it after the other
  existing ones without needing a restart

- Correctly handle room topics containing new lines, hard tabs or text inside
  `<>` brackets 

- Starting a direct chat, creating or joining a room will now correctly 
  update the left pane room list's highlighted item

- Fix `KeyError` when forgetting a room

- Fix cursor shape not changing to caret when hovering text fields and areas.
  This fix can only apply when the `enableKineticScrolling` setting is `true`,
  until the project switches to Qt 5.15.


## 0.5.0 (2020-05-22)

### Added

- **Unread messages and mentions**:
  - Rooms in the left pane will now have a counter for unread messages and 
    times you were mentioned

  - `goToPreviousUnreadRoom` (default Alt+Shift+U) and
    `goToNextUnreadRoom` (default Alt+U) keybinds to cycle between rooms
    with unread messages

  - `goToPreviousMentionedRoom` (default Alt+Shift+M) and
    `goToNextMentionedRoom` (default Alt+M) keybinds to cycle between rooms
    with mentions, or those with unread messages if no rooms with mentions
    are left

  - Room with mentions will be sorted first, then room no mentions but unread
    messages, then the rest

- **Accounts navigation**:
  - With two or more accounts, an always visible account thumbnail grid will
    be visible in the left pane.  
    Clicking on an account will make the room list jump to that account.  
    The accounts will also show a total number of unread messages and
    mentions for all the rooms associated with it.

  - `goToPreviousAccount` (default Alt+Shift+M) and 
    `goToNextAccount` (default Alt+M) keybinds to cycle and jump between
    accounts in the room list. 

  - `keys.focusAccountAtIndex` in config file, a `{"<index>": "<keybind>"}`
    mapping similar to `focusRoomAtIndex` which by default binds
    Ctrl+1-9 and Ctrl+0 to jump to account 1 to 10 in the room list

- **Replies**:
  - The context menu for messages now has a "Reply" option

  - The new `replyToFocusedOrLastMessage` keybind (default Ctrl+Q) can be used
    to reply to the focused message if any
    (use the `focusPreviousMessage` and `focusNextMessage` keybinds), 
    or to the last message in the timeline not sent by you.

  - Pressing escape will cancel the reply 

- **Kick and bans**: room members can now be kicked or banned with an optional
  reason, using the option in the right pane's member context menu 

- `openMessagesLinks` keybind (default Ctrl+O).  
  Will open externally all the URLs present in the selected/focused message(s),
  or the last message that contains links if none are selected or focused.

- `clearMemberFilterOnEscape` setting.  
  If `true` (default), 
  pressing escape while focusing the "Filter members" field will not only
  focus the chat again but also clear the filter.

- `maxMessageCharactersPerLine` setting to control the maximum width of
  messages. If set to `-1`, there will be no limit.

- `ownMessagesOnLeftAboveWidth` setting, replaces the themes's
  `eventList.ownEventsOnRightUnderWidth` properties.  
  Can be set to `-1` to always keep your own messages on the right.

- `enableKineticScrolling` setting, try setting it to `false` if you have
  scrolling issues on a trackpad 

- Support a new `enabled` key for accounts in the accounts.json config file. 
  If set to `false`, Mirage will not login to or show the account on startup.

- Support a new `order` key for accounts in the accounts.json config file
  The value is an integer that will determine how accounts in the left pane 
  are sorted, lower comes first.  
  If multiple accounts have the same `order` value, they are sorted by 
  their user ID.

- Themes:
  - `mainPane.minimumSize` property
  - `mainPane.accountBar` section
  - `mainPane.listView.room.unreadIndicator` section
  - `chat.replyBar` section

### Changed

- **Performance**:
  - Use room members lazy-loading, accounts that have joined
    large numbers of rooms will now finally be able to finish their
    initial sync.  
    When the currently shown UI page is a room, the full members list for it 
    will be loaded.

  - Request less events for the initial sync, and exclude some types like 
    membership events to increase initial sync speed

  - Retrieving profiles for events sent by users no longer present in a room
    will no block and delay past events loading.  
    Missing profiles will be fetched asynchronously when the messages
    are currently in view in the UI.

  - Reduce the number of events that need to be sent between Python and QML
    due to changes in list models data

  - Consecutive syncs will now have a one second delay between them to reduce
    both client and server strain 

- Improved group display name calculations (nio 0.11+ change):  
  for example, a room that would previously be shown as "Alice and 6 others"
  will now be shown as "Alice, Bob, Carol, Dave, Erin and 1 other"
  (up to 5 visible names).

- Group rooms with more than two users and without an explicitely set avatar
  will no longer show their first member's profile picture as avatar

- The `unfocusOrDeselectAllMessages` keybind now defaults to Ctrl+D
  instead of Escape, which no longer works as of Qt 5.14.
  `debugFocusedMessage` is changed from Ctrl+D to Ctrl+Shift+D.

- Better QML logging format: messages will now be dated, and have a
  symbol + color (on Linux and OSX terminals) representing their category

- Messages containing code blocks will no longer have their max width limited

- Set `hideUnknownEvents` to `true` in the default config file

- Set a more useful default minimum size for the left pane

- The `collapseSidePanesUnderWindowWidth` setting now defaults to `450` instead
  of `400`, to account for the larger minimum pane size.

- Show a more useful error message with traceback when retrieving an account's
  profile or the server config fails on startup

- Hide `socket.gaierror` error popups

- When pressing the `startPythonDebugger` (default Alt+Shift+D) keybind, 
  use `pdb` if `remote_pdb` isn't installed

- Themes:
  - `mainPane.bottomBar` properties: `background` is now by default
    `transparent`, `settingsButtonBackground` and `filterFieldBackground` are
    now set to `colors.strongBackground`

### Removed

- **Performance**:
  - After the initial sync, Mirage will no longer try to continually fetch
    previous events for rooms where the sync haven't brought any event that is
    suitable to be shown as room last event subtitle in the left pane.

  - Mirage will no longer try to find and autolink display names in incoming
    events, which was a very costly operation for rooms with
    thousands of members.

- The uvloop python module is no longer supported or recommended as an optional
  dependency, due to being responsible for some segfaults

- The SortFilterProxyModel and RadialBarDemo git submodules are no longer
  used. hsluv-c is the only submodule still used currently.

### Fixed

- **Performance**:
  - Stop rendering and keeping in RAM rooms that aren't currently visible in
    the left pane.  
    This fixes the massive memory usage that occurred with hundreds of rooms
    and their avatar images loaded all at once.

  - Room elements in the left pane will no longer be reloaded every time 
    a list movement happens (e.g. a room is bumped to the top due to a new 
    message).  
    This also lets the movement animation correctly play instead of being
    skipped.

- Don't show a popup when pressing the redact message keybind if that
  message can't be redacted

- Stricter mention parsing, fix various cases of text being autolinked when it
  shouldn't 

- Fix exception when parsing `<a>` HTML tags without `href` attribute

- Fix crash on Python 3.6 due to `asyncio.current_task` 

- Fix `AttributeError` when using matrix-nio v0.11+

- Fix potential crash on startup due to asyncio event loop and threading

- Fix uploads getting rejected by servers due to not passing a file size

- Fix extra spacing between "Add chat" and "Expand/Collapse" account buttons 

- Hide the Binding deprecation warnings in terminal that Qt 5.14+ spams

- Fix client not waiting before retrying a failed sync due to server error

- Correctly handle server 429 "Too many requests" errors when they come purely 
  in the form of a HTTP status code without a JSON object giving any info

- Fix left rooms remaining at full opacity in the left pane

- Fix escape key not working to clear the "Filter rooms" field and focus 
  the chat again

- Fix event mention link detection, and stop trying to autolink event ID
  strings in messages as matrix.to URLs also need a room ID to make sense


## 0.4.3 (2020-04-03)

### Added

- Support for `MIRAGE_CONFIG_DIR` and `MIRAGE_DATA_DIR` environment variables
  to change the config and user data folders 

- `inviteToRoom`, `leaveRoom` and `forgetRoom` keybindings
  (Alt+I, Alt+Esc and Alt+Shift+Esc by default)

- **Redactions support**: individual or selected messages can now be
  redacted/removed using the option from the message context menu,
  or the `removeFocusedOrSelectedMessages` keybind
  (by default Ctrl+R or Alt+Del).

- Themes: `colors.dimColoredTextSaturation` and
  `colors.dimColoredTextIntensity` color properties

- Themes: `controls.displayName.dimSaturation` and
  `controls.displayName.dimLightness` color properties

- Themes: `chat.message.redactedBody` color property

### Changed

- `unfocusOrDeselectAllMessages` keybind: now deselect messages first if any
  on first press, *then* cancels the keyboard message focus if possible on
  second press 

### Fixed

- Segfault after login on KDE

- Buttons not displaying correctly on Qt 5.14

- Hard tab characters in theme files not being handled by the theme parser

- `focusRoomAtIndex` keybindings: default to Cmd+numbers on OSX instead of
  Alt/Option+numbers, which prevented typing special characters on some
  keyboard layouts

- Needing to press escape twice to close context menus and popups

- "Go back to chat" button not doing anything when the room settings pane was
  focused in narrow mode


## 0.4.2 (2020-03-27)

### Added

- Accounts, rooms, room members and messages can now be long-tapped on touch
  screens to open their context menu

- New touch screen and keyboard-friendly message selection system, replaces
  the previous slow and buggy text selection implementation:

  - Tap a message to select or deselect it

  - Press escape, or use the context menu entry "Deselect all" to deselect
    all messages

  - Tap a first message, then shift+tap another one
    (or use "Select until here" from the context menu) to select all messages
    from the first to last

  - With a mouse, a single message can be partially selected and copied

  - The keyboard can be used to navigate with Ctrl+Up/Down (or Ctrl+J/K),
    Ctrl+Space to (de)select, Ctrl+Shift+Space for first-to-last selection,
    Ctrl+C for copying the selection, and Escape to focus the composer again
    (twice to also deselect messages).
    These shortcuts can be changed in the config file.

- Themes: `chat.message.focusedHighlight`,
  `chat.message.focusedHighlightOpacity`, `chat.message.checkedBackground` and
  `chat.message.thumbnailCheckedOverlayOpacity`

- Scripts and instructions to build a Flatpak package

The new selection system is still work in progress, dragging to select multiple
messages at once on desktop is not implemented yet.

### Changed

- Themes: increased default `colors.accentBackground` brightness

### Fixed

- Possible error when handling a room member event that is missing previous
  display name or avatar info

- Correctly parse `mailto:` links where the mail address ends with a digit
  (e.g. `mailto:foo@localhost:8050`, or where the host is a single character

- Respect case when turning display names into mentions, typing a display name
  containing uppercase letters all in lowercase would result in a broken link

- Correctly handle `0` as a value for the `alertOnMessageForMsec` setting,
  this will now prevent urgency hints (window/desktop highlighting or flashing
  on new message for most desktops, "ready" notification on Gnome)


## 0.4.1 (2020-03-23)

### Added

- `hideMembershipEvents` setting, controls whether events such as
  "x joined the room" are shown in the timeline.

- `hideProfileChangeEvents` setting, controls whether display name and avatar
  change events are shown in the timeline.

- `hideUnknownEvents` setting, controls whether events not yet supported by
  Mirage (e.g. `m.reaction`) are shown in the timeline.

- Compact mode to make accounts, rooms, messages and room members take only
  one line as well as reducing vertical spacing between them.
  Set by the new `compactMode` setting in config file, can also be toggled
  with the `keys.toggleCompactMode` keybind which defaults to Alt+Ctrl+C.

- `keys.focusRoomAtIndex` in config file, a `{"<index>": "<keybind>"}` mapping
  which by default binds Alt+1-9 and Alt-0 to focus room 1 to 10
  in the current account.

- User ID, display names, room ID, room aliases and message ID are now
  automatically turned into [matrix.to](https://matrix.to) links and will be
  rendered as mentions by clients.
  In Mirage, user ID/names will be colored with the same color seen when they
  send messages.

- Track the number of times your user was mentioned in rooms.
  The visual counter is not yet displayed, since there currently is no way
  to mark messages as read and make the counter go down.

- Themes: `controls.avatar.compactSize` property
- Themes: mention classes styling to `chat.message.styleSheet`

### Fixed

- Python exceptions occurring in the asyncio loop not being printed in
  the terminal

- Extra newline shown after code blocks in messages

- Constant CPU usage due to button loading animations still being rendered
  while unneeded and invisible


## 0.4.0 (2020-03-21)

Initial public release.
