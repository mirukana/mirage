- Refactoring
  - Use new H\* components everywhere
  - TextInput.accepted() for SendBox
  - Migrate more JS functions to their own files / Implement in Python instead
  - Don't bake in size properties for components
  - Better names and organization for the Message components

- Bug fixes
  - 100% CPU usage when hitting top edge to trigger messages loading
  - Fix tooltip hide()
  - Sending `![A picture](https://picsum.photos/256/256)` → not clickable?
  - Icons aren't reloaded
  - Bug when resizing window being tiled (i3), can't figure it out
  - HStyle singleton isn't reloaded

- UI
  - Server selection
  - Register/Forgot? for SignIn dialog
  - Scaling
    - See [Text.fontSizeMode](https://doc.qt.io/qt-5/qml-qtquick-text.html#fontSizeMode-prop)
  - Test HGlassRectangle elements when no effects are available
  - Leave room
  - Forget room warning popup
  - Use HRowLayout and its totalSpacing wherever possible
  - Spacer component
  - One line label componant
  - Proper button background componant
  - Collapsible roomList sections, + button
  - Prevent using the SendBox if no permission (power levels)
  - Spinner when loading past room events, images or clicking buttons
  - Reorganize SidePane
  - Proper theme, with components taking their colors from theme settings
  - Settings page
    - Multiaccount aliases

- Major features
  - E2E
  - Uploads
  - Links preview
  - QQuickImageProvider
  - Read receipts
  - Status message and presence

- Client improvements
  - HTTP/2
  - `retry_after_ms` when rate-limited
  - Direct chats category
  - On sync, check messages API, if a limited sync timeline was received
  - Markdown: don't turn #things into title (space), disable __ syntax
  - Push instead of replacing in stack view
  - Make links in room subtitle clickable, formatting?
  - `<pre>` scrollbar on overflow
  - Use Loader? for MessageDelegate to show sub-components based on condition
  - Handle cases where an avatar char is # or @ (#alias room, @user\_id)
  - Proper logoff when closing client
  - When inviting someone to direct chat, room is "Empty room" until accepted,
    it should be the peer's display name instead.
  - Keep an accounts order
  - See `Qt.callLater()` potential usages
  - Banner name color instead of bold

- Missing nio support
  - Left room events
  - `org.matrix.room.preview_urls` event
  - `m.room.aliases` event
  - Support "Empty room (was ...)" after peer left

- Waiting for approval/release
  - nio avatars
  - olm/olm-devel 0.3.1 in void repos
  - html-sanitizer allowed attributes fix pypi release

- Distribution
  - Review setup.py, add dependencies
  - REAMDE.md
