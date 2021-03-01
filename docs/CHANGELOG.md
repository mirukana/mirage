# Changelog

All notable changes will be documented in this file.  
The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

- [0.7.0 (2021-02-28)](#070-2021-02-28)
- [0.6.4 (2020-09-16)](#064-2020-09-16)
- [0.6.3 (2020-09-16)](#063-2020-09-16)
- [0.6.2 (2020-08-28)](#062-2020-08-28)
- [0.6.1 (2020-08-21)](#061-2020-08-21)
- [0.6.0 (2020-07-17)](#060-2020-07-17)
- [0.5.2 (2020-06-26)](#052-2020-06-26)
- [0.5.1 (2020-06-05)](#051-2020-06-05)
- [0.5.0 (2020-05-22)](#050-2020-05-22)
- [0.4.3 (2020-04-03)](#043-2020-04-03)
- [0.4.2 (2020-03-27)](#042-2020-03-27)
- [0.4.1 (2020-03-23)](#041-2020-03-23)
- [0.4.0 (2020-03-21)](#040-2020-03-21)


## 0.7.0 (2021-02-28)

### Added

- **Push rules and notifications support**: 
  - Add native desktop notifications support
  - Add sound effect playback support 
  - Add button and keybinds to mute all notifications in the running client
  - Add notification context menu options to rooms in the left pane 
  - Add a push rule editor to account settings:
    - Control for any rule whether matching messages are 
      marked as unread, highlighted, trigger a desktop notification, 
      sound, window alert, or any combination of those actions

    - Create custom rules targeting a particular room, message sender,
      messages containing certain words or messages matching
      advanced conditions

- **New configuration system** replacing the previous `settings.json`,
  see the 
  [documentation](https://github.com/mirukana/mirage/blob/master/docs/CONFIG.md) 
  for more info

- Rooms in the left pane can now be pinned to the top of the list, using the
  added context menu option or config file setting

- Support drag-and-dropping text and files to upload in chats

- Add tooltips to the message read counters, listing who has read a message and
  when. Tooltips can also be shown for the keyboard-focused message using a
  keybind.

- The chat header now indicates when messages are selected in the timeline,
  and offers copy/redact/clear selection buttons 

- Add a visible indicator when downloading files 

- Add command-line arguments parsing and a `--start-in-tray` option, see 
  `mirage --help`

- Hovering on stability percentages in the sign-in page's homeserver list 
  now shows more detailed tooltips about the server's recent downtimes

### Changed

- Config files and theme (with the exception of `accounts.json`) are now 
  automatically reloaded when changed on disk 

- The top-left settings button now opens a menu giving access to the 
  settings folder, theme folder and developer console

- Clicking on the "Mirage x.y.z" text in the top left no longer opens the 
  github page 

- Merge the "Encryption" and "Sessions" account settings tabs into a new 
  "Security" tab

- Developer console improvements:
  - Improve default colors and provide clearer separation of different 
    commands's outputs
  - Support multi-line input, use shift+return to insert a newline
  - The output text can now be selected and copied

- Improve room page loading speed 

- When replying to a message, pressing the reply keybind again while focusing
  on that message will now cancel the reply

- Make user ID in account settings a copiable read-only text field

- Hide useless context menu entries for read-only text fields (undo/paste/etc)

- Make the scroll to top/bottom keybinds work faster for long timelines and 
  be more accurate 

- Better explain why not all selected messages can be removed in the 
  message removal confirmation popup

- When clicking on an account in the top left account bar or using the 
  previous/next account keybinds, focus the account settings instead of 
  the account's first room

- While keyboard-focusing an image message, hide its sender and time bubbles
  as if it was hovered by mouse

- Color key words in invite/leave/forget/error popups instead of using italic

- Apply theme radius on context menus

- Theming:
  - Reduce default `fontSize.big` from `22` to `20`
  - Change the default style of room unread indicators
  - Add new properties to the `mainPane.accountBar.account.unreadIndicator`
    and `mainPane.listView.room.unreadIndicator` sections, see
    [620b5815](https://github.com/mirukana/mirage/commit/620b58151d7d9d15e242402da34ef55a05549ca5#diff-fdb828d814eca61316a31204666263a410da6dd9c1cf0099dbf54da9e82e33e1)


### Fixed

- Fix build failing on Python 3.9 due to incompatible `blist` dependency

- Fix event context menu "Reply" option targetting the wrong message

- Fix read counter on image events lacking color and having extra padding

- Prevent opening multiple instances of the same context menu by right clicking
  or using keybinds 

- Fix current page not being highlighted in the left pane when Mirage starts 
  and the initial page to load is an account settings page

- Fix list delegates (especially left pane rooms) occasionally appearing as 
  invisible items 

- Fix incorrect user ID text hue in account settings

- Close the reply bar when switching to another room while composing a reply

- Fix "Copy link address" entry in message context menu not being visible 

- Fix some characters being rendered incorrectly in redacted messages reasons
  (e.g. `<test>` was shown as `&lt;test&gt;`)

- Fix cancel button in the "Join Room" page not returning to previous page 

- Fix Matrix server errors lacking a `M_CODE` triggering an account logout 

- Fix "Go to previous/next unread/highlighted room" keybinds ignoring rooms 
  with a local unread counter ([!] markers)

- Fix copying multi-line mouse-selected rich text, newlines were not preserved

- Prevent warnings spam when the XScreenSaver protocol is available but not 
  supported, e.g. when running in XWayland

- Fix message timeline occasionally breaking and mixing messages from multiple 
  rooms when switching room

- Show an error when loading a JSON config file fails instead of silently 
  failing and using a default configuration, which can potentially overwrite
  user files

- Fix "focus previous/next message" keybinds sometimes skipping messages and 
  focusing the middle of the screen while the timeline scrolling 
  was at the bottom 

- Fix read marker updates sometimes getting stuck and never clearing the unread
  message counts for a room

- Fix scroll keybinds not working when kinetic scrolling is disabled

- Fix chat right pane having an invisible 10px edge when hidden/collapsed, 
  interfering with any button in the way

- Fix the "expand right pane" button failing to bring back the pane and
  turning the chat room header invisible 

- Fix "open debug console for this message" keybind erroring

- Prevent horizontal dragging of flickable column layout pages

- Fix scrolling keybinds not working to scroll popups 

- Revert 0.6.2's message combining fix, which caused message bubble movements
  to randomly stop in the middle of their animations and be left at odd 
  positions or overlap with other bubbles


## 0.6.4 (2020-09-16)

### Fixed

- Fix checkboxes in the room settings not having their default values updated
  after switching room

- Fix various minor features broken on Qt 5.12 and the AppImage since v0.5.2


## 0.6.3 (2020-09-16)

### Added

- Add a **system tray icon**.  
  A left click will bring up the Mirage window, 
  middle will quit the application and right will show a menu with these 
  options.

- Add a `closeMimizesToTray` setting to the config file, defaults to `false`.  
  Controls whether closing the Mirage window will leave it running in the 
  system tray, or fully quit the application.

- Add a discrete **read marker indicator** to messages, shows how many people 
  have this event as their last seen one in the room.  
  A way to see who read the message and when will be added in the future.

- Themes: add `chat.message.localEcho` and `chat.message.readCounter` color
  properties

- Add a `zoom` setting, defaults to `1.0`

- Add a `lexicalRoomSorting` setting, to sort rooms by their name instead of
  recent activity.  
  A restart is needed to apply changes to this setting.

### Changed

- Restrict Mirage to a single instance per config folder, trying to launch a
  new window will instead focus the existing one.  
  The `MIRAGE_CONFIG_DIR` and `MIRAGE_DATA_DIR` environment variables can be
  set to run different "profiles" in parallel.

- Reduce the visible lag when opening a chat page, switching rooms should be 
  a lot smoother

- When using the `focusPreviousMessage` and `focusNextMessage` keybinds, if no
  message is focused and the timeline has been scrolled up, 
  focus the message in the center of the view instead of returning to the 
  bottom of the timeline and focusing the last one.

- Don't re-center the room list on clicks by default.  
  This prevents the list from jumping around every time a room is selected.  
  The previous behavior can be restored with the new `centerRoomListOnClick`
  setting.

- Show a better terminal error message than "Component is not ready" when the 
  window creation fails, giving details on what went wrong in the code

- If an account's access token is invalid (e.g. our session was signed out 
  externally), say so with a popup and cleanly remove it from the UI, 
  instead of spamming the user with errors.

- Rename message context menu option "Debug this event" to just "Debug"

- Unify up/down and (shift+)Tab navigation for the account Sessions page

- Changes to the UI scale/zoom via keybinds are now persisted across restarts

- Themes: `uiScale` is now bound to `window.settings.zoom`.  
  This change is necessary to keep the zoom keybinds working.

### Fixed

- Midnight theme: fix missing `}` from change to the `chat.message.styleSheet` 
  property introduced in 0.6.2, see
  [2a0f6ae](https://github.com/mirukana/mirage/commit/2a0f6aead17d05fd35e8a944e5434781e9c08d50).

- Fix multiple consecutive one-line events (/me emotes, "x joined", etc) 
  not combining properly

- Fix theme finder ignoring the `MIRAGE_DATA_DIR` environment variable

- Fix theme background image not updating when reloading theme/settings

- Fix up/down keys not working when the text cursor is in a word starting 
  with `@`, but the word doesn't match any usernames to complete.

- Fix context menu copy options for messages containing URL thumbnails

- Fix context menu copy option for single non-message events

- Fix GIF URL thumbnails not being animated in the timeline

- Fix image viewer sizes shown as "0x0" for loading images and GIFs

- Fix incorrect sync filter usage introduced in 0.6.1, which caused problems
  like redaction events never arriving

- Fix redacted media messages keeping their thumbnails

- Fix terminal warnings when uploading to a non-encrypted room

- Fix some cases of undetected power level changes, e.g. a muted user 
  (level -1) going back to the default (level 0).

- Don't show popup for `400 M_UNRECOGNIZED` errors that can occur when trying
  to fetch an offline user's presence

- Focus the filter field again when exiting a room member profile page


## 0.6.2 (2020-08-28)

### Changed

- When replying to a message, you can now press enter without entering any
  text to send it directly (useful to "forward" a message).

- Sending a file while replying to a message will create a pseudo-reply,
  consisting of an "In reply to" text message with no body, followed by the
  actual file event.
  This is a workaround to the reply restrictions imposed by the Matrix spec.

- **Composer aliases cannot contain whitespace anymore.**
  This includes spaces, hard tabs or newline characters.
  If an alias from your config still has whitespace, only the first word
  will be taken into account (ignoring any leading or trailing space).

- Faster server browser loading, now gathers all needed data with a
  single request instead of one for each server

- Auto-focus the "Join" button on invited room pages
  ((Shift+)Tab can be used to navigate between buttons)

- Auto-focus the "Forget" button on left room pages

- Themes: modify `chat.message.styleSheet` to add some spacing between HTML 
  list items, see
  [48663ae](https://github.com/mirukana/mirage/commit/48663ae8465e90646855435b47b89c01395ae4d9)

### Fixed

- Fix @username autocompletion closing if there's more than one character
  after the @

- Consider the partial text from IME (input method editors) and touch screen 
  autocompleting keyboards for username autocompletion

- Reset IME state upon autocompleting a username

- Fix clicking on autocompletion list user not making the username a mention

- Fix UI freezing when mentioning user lacking a display name

- Fix mentioning users with blank display name (e.g. only spaces), mention
  them by their user ID

- Fix text fields/areas unable to be focused on touch screen

- Fix random chance of profile retrieval requests failing if one of the logged
  in account doesn't federate with other servers (e.g. localhost synapse)

- Fix composer text saved to disk for the wrong account if that text begins
  by an account alias

- Servers can potentially return an outdated member list for rooms on initial 
  sync, which is one of the possible cause of "Members not synced" error for 
  encrypted rooms.  
  When loading the full room list, discard members from the initial sync list
  that are absent from the full list.
  For those not using the AppImage or Flatpak, 
  this fix requires **matrix-nio 0.15.1** or later to take effect.

- When erasing an account alias inside the composer, send a 
  "x isn't typing anymore" notification corresponding to that account 

- Fix potential 403 error on chat pages for invited rooms.

- Start loading room history immediately when the room join state changes,
  e.g. when clicked "Join" for an invited room page.


## 0.6.1 (2020-08-21)

### Added

- **SSO authentication** support

- **Homeserver browser**:
  - To add a new account, you will be asked first to pick one of the 
    listed public server 
    (list data from [anchel.nl](https://publiclist.anchel.nl/))
    or to manually enter a server address 

  - Typing in the server address field will also filter the public server list, 
    Up/Down or (Shift+)Tab and Enter can be used to navigate it by keyboard

  - If the address doesn't have a `scheme://`, auto-detect whether the server
    supports HTTPS or only HTTP

  - Use the .well-known API if possible to resolve domains to the actual 
    homeserver's URL, e.g. `matrix.org` resolves to 
    `https://matrix-client.matrix.org`

  - The server address field will remember the last homeserver that was
    connected to

- **Room members autocompletion**:
  - Type `@` followed by one or more characters in the composer, 
    or one or more characters and hit (Shift+)Tab to trigger username/user ID
    autocompletion

  - Only autocompleted names will be turned into mentions, unlike before
    where any word in a sent message that happened to be someone's name would 
    mention them

- **Full image viewer** for matrix image messages and URL previews:
  - Click on a thumbnail in the timeline to open the image viewer

  - Middle click on a thumbnail (or use the option in the context menu)
    to open the image externally

  - Left click on the image (mouse only): expand to window size if the 
    image's origin size is smaller than the window, 
    else expand to original size

  - Tap on the image (touch screen/pen only): reveal the info and button bars
    when auto-hidden (bars will auto-hide only when they overlap with a big 
    enough displayed image)

  - Any mouse movement: reveal auto-hidden bars
  - Double click on the image: toggle full screen
  - Middle click anywhere: open externally
  - Right click anywhere: close the viewer, back to chat
  - Drag when displayed image is bigger than window to pan
  - Wheel to pan up/down, hold shift or alt to pan left/right
  - Ctrl+wheel to control zoom
  - Buttons to control rotation, scale mode, full screen, GIF play/pause 
    and GIF speed

  - New keyboard shortcuts are available for all these actions, 
    see `keys.imageViewer` in the config file (will be automatically updated 
    when you start Mirage 0.6.1)

- Add `media.openExternallyOnClick` setting to swap the new
  click and middle click on thumbnails behavior 

- Add `openMessagesLinksOrFilesExternally` keybind, by default Ctrl+Shift+O

- Add `copyFilesLocalPath` keybind, by default Ctrl+Shift+C

- Room and member filter fields now support (Shift+)Tab navigation, in addition
  to Up/Down

- Add a colored left border to the currently highlighted item in list views 
  (e.g. room list, members list, etc) to improve visibility 

- Themes:
  - Add `controls.listView.highlightBorder` and
    `controls.listView.highlightBorderThickness` properties (can be set to `0`)
  - Add the `chat.userAutoCompletion` section

### Changed

- Messages context menu:
  - Use a cleaner icon for the "Copy text" entry

  - Replace the confusing broken "Copy media address" entry with:
    - Copy media address: visible for non-encrypted media, always
      copies the HTTP URL

    - Copy local path: always visible for already downloaded media, even if
      they were downloaded before mirage was started

- The `openMessagesLinks` keybind (default Ctrl+O) is renamed to
  `openMessagesLinksOrFiles` and can now also open media message files

- Using the `openMessagesLinksOrFiles` keybind on a reply will now ignore the
  matrix.to links contained in the "In reply to XYZ" header

- Pressing Ctrl+C to copy selected/highlighted non-encrypted media messages 
  will copy their HTTP URL instead of the filename

- Retry downloading image thumbnails if they fail with a 404 or 500+ server 
  error (uploads sometimes take a few seconds to become available on the 
  server)

- Non-encrypted media messages are now always downloaded on click and opened
  with a desktop application (or the image viewer), instead of
  being opened in a browser

- Compress thumbnails and clipboard images in a separate process, to avoid
  blocking every other backend operation while the compression is running

- Reduce the level of optimization applied to clipboard images, 
  the previous setting was too slow for large PNG (10MB+)

- Increase applied scrolling velocity when using the 
  `scrollPageUp`/`scrollPageDown` keybinds, now similar to how it was before
  Mirage 0.6.0

- Don't catch SIGQUIT (Ctrl+\ in terminal) and SIGTERM signals, 
  exit immediately

- Slightly increase the top/bottom padding to the multi-account bar in the 
  left pane

- Dependencies: minimum nio version bumped to 0.15.0

### Removed

- Themes: remove unused `controls.listView.smallPaneHighlight` property

### Fixed

- Don't show account avatar tooltips when the context menu is open

- Don't automatically focus member power level control when grayed out

- Fix uploading files for servers not telling us their maximum allowed
  file size

- Fix message context menu "Copy text": when an event was highlighted with 
  the keyboard, right clicking a message and clicking "Copy text" would always 
  copy the message that was highlighted instead of the one the user aimed for.

- Fix pressing menu key in chat opening both the composer's and the timeline's
  context menus

- Fix random chance of failure when fetching thumbnails or user profiles and
  an account other than the current one is offline

- Catch potential 403 errors when fetching presence for offline room members

- Fix room right pane stealing focus from opened popup when resizing the window
  from narrow/mobile mode to normal mode

- Never try to send typing notifications in rooms where we don't have 
  permission to talk

- Fix clipboard upload preview popup not updating when the copied image changes

- Fix some pages not respecting `enableKineticScrolling: false` setting

- Fix truncated "Loading previous messag..." text in timeline

- Fix possible race condition corrupting user config files on write

- Fix missing member events from initial syncs, also fixes some cases
  of the "Members not synced" error occurring in encrypted rooms where members
  have recently joined or left.

- Fetch missing member display name when displaying last messages in room pane 
  for rooms that haven't had their members list fully loaded yet

- Use uploaded sync filter IDs in sync requests instead of passing a long
  JSON object in the URL every time, which caused problems on some servers with
  a short URL length limit (e.g. halogen.city)

- Fix autolinking user IDs that include `;` or `<` characters

- Ignore enter keypresses in pages or popups when the accept button is grayed
  out

- Fix never-ending spinner in left pane when logging in to an account that was
  already connected


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
