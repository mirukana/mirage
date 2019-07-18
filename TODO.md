- Devices and client settings in edit account page
- If avatar is set, name color from average color?
- Accent color from background
- Reduce messages ListView cacheBuffer height once http thumbnails
  downloading is implemented 
- Improve avatar tooltips position, add stuff to room tooltips (last msg?)
- Accept drag and dropping a picture in account settings to set avatar
- When all the events loaded on beginning in a room are name/avatar changes,
  no last event room text is displayed (use sync filter?)
-  `QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling)` ?

- Qt 5.12
  - .mjs modules

- Refactoring
  - Don't bake in size properties for components
  - Unfinished work in button-refactor branch
    - Button can get "hoverEnabled: false" to let HoverHandlers work
  - Room Sidepane
  - When qml syntax highlighting supports string interpolation, use them

- Bug fixes
  - Past events loading (limit 100) freezes the GUI - need to move upsert func
    to a WorkerScript
  - `MessageDelegate.qml:63: TypeError: 'reloadPreviousItem' not a function`
  - Horrible performance for big rooms

- UI
  - "Rejoin" LeftBanner button if room is public
  - Daybreak color
  - Html links color
  - Don't put own messages to the right past certain width
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
  - Scaling
    - See [Text.fontSizeMode](https://doc.qt.io/qt-5/qml-qtquick-text.html#fontSizeMode-prop)
  - Add room
  - Leave room
  - Forget room warning popup
  - Prevent using the SendBox if no permission (power levels)
  - Spinner when loading past room events, images or clicking buttons
  - Better theming/styling system
  - Settings page
    - Multiaccount aliases
  - Message/text selection

  - Custom file picker for Linux...
  - Way to round avatar corners to allow box radius

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
  - Handle TimeoutError for all kind of async requests (nio)
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
