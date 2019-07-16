- Can set `Layout.fillWidth: true` to elide/wrap 
- Use childrenRect stuff
- Rename theme.bottomElementsHeight
- Account delegate name color
- If avatar is set, name color from average color?
- normalSpacing in Theme
- banner button repair
- Wrong avatar for group rooms
- Make sure to not cache user images and that sourceSize is set everywhere
- Reduce messages ListView cacheBuffer height once http thumbnails
  downloading is implemented 
- HTextField focus effect
- Button can get "hoverEnabled: false" to let HoverHandlers work
- Handle TimeoutError for all kind of async requests (nio)
- Handle thumbnail response status 400
- "Loading..." if going to edit account page while it's loading
- Improve avatar tooltips position, add stuff to room tooltips (last msg?)
- Accept drag and dropping a picture in account settings to set avatar
- When all the events loaded on beginning in a room are name/avatar changes,
  no last event room text is displayed

- Qt 5.12
  - New input handlers
  - ECMAScript 7
  - .mjs modules

- Refactoring
  - Don't bake in size properties for components
  - Unfinished work in button-refactor branch

- Bug fixes
  - Past events loading (limit 100) freezes the GUI - need to move upsert func
    to a WorkerScript
  - `MessageDelegate.qml:63: TypeError: 'reloadPreviousItem' not a function`
  - Horrible performance for big rooms

- UI
  - "Rejoin" LeftBanner button if room is public
  - Daybreak color
  - Html links color
  - `pyotherside.atexit()`
  - Way to put sidepane back to auto-sizing (snap)
  - Better look for arrows when sidepane collapsed
  - Don't put own messages to the right past certain width

  - Invite to room
  - Accounts delegates background
  - SidePane delegates hover effect
  - Server selection
  - Register/Forgot? for SignIn dialog
  - Scaling
    - See [Text.fontSizeMode](https://doc.qt.io/qt-5/qml-qtquick-text.html#fontSizeMode-prop)
  - Add room
  - Leave room
  - Forget room warning popup
  - Prevent using the SendBox if no permission (power levels)
  - Spinner when loading past room events, images or clicking buttons
  - Better theming/styling system
    - See about <https://doc.qt.io/qt-5/qtquickcontrols2-configuration.html>
  - Settings page
    - Multiaccount aliases
  - Message/text selection

  - Custom file picker for Linux...

- Major features
  - E2E
    - Device verification
    - Edit/delete own devices
    - Request room keys from own other devices
    - Auto-trust accounts within the same client
    - Import/export keys
  - Uploads
  - QQuickImageProvider
  - Read receipts
  - Status message and presence
  - Links preview

- Client improvements
  - [debug mode](https://docs.python.org/3/library/asyncio-dev.html)
  - Filtering rooms: search more than display names?
  - Initial sync filter and lazy load, see weechat-matrix `_handle_login()`
    - See also `handle_response()`'s `keys_query` request
  - Direct chats category
  - On sync, check messages API, if a limited sync timeline was received
  - Markdown: don't turn #things (no space) and `thing\n---` into title,
    disable `__` syntax for bold/italic
  - Push instead of replacing in stack view (remove getMemberFilter when done)
  - `<pre>` scrollbar on overflow
  - When inviting someone to direct chat, room is "Empty room" until accepted,
    it should be the peer's display name instead.
  - See `Qt.callLater()` potential usages
  - Animate RoomEventDelegate DayBreak apparition
  - Room subtitle: show things like "*Image*" instead of blank, etc

- Missing nio support
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
