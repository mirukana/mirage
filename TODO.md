- invite/leave/forget backend funcs
- license headers
- replace "property var" by "property <object>" where applicable and
  var by string and readonly
- [debug mode](https://docs.python.org/3/library/asyncio-dev.html)
- `pyotherside.atexit()`
- way to put sidepane back to auto-sizing (snap)
- better look for arrows when sidepane collapsed

ideas
(^/v) messages unread + messages still sending
sticky avatar at top
ability to cancel message being sent

nio
fix `RoomForgetResponse.create_error`

OLD

- Refactoring
  - Migrate more JS functions to their own files / Implement in Python instead
  - Don't bake in size properties for components

- Bug fixes
  - Past events loading (limit 100) freezes the GUI - need to move upsert func
    to a WorkerScript
  - Past events loading: text binding loop on name request
  - `MessageDelegate.qml:63: TypeError: 'reloadPreviousItem' not a function`

- UI
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
  - Filtering rooms: search more than display names?
  - nio.MatrixRoom has `typing_users`, no need to handle it on our own
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

- Distribution
  - List dependencies
  - README.md
