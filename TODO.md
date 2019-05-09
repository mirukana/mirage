- Refactoring
  - Migrate more JS functions to their own files / Implement in Python instead
  - Don't bake in size properties for components
  - Cleanup unused icons

- Bug fixes
  - Local echo messages all have the same time
  - Something weird happening when nio store is created first time
  - 100% CPU usage when hitting top edge to trigger messages loading
  - Sending `![A picture](https://picsum.photos/256/256)` → not clickable?
  - Icons, images and HStyle singleton aren't reloaded
  - `MessageDelegate.qml:63: TypeError: 'reloadPreviousItem' not a function`

- UI
  - "the tree arrows could be smaller"
  - Improve SidePane appearance when at min width
  - Accounts delegates background
  - Server selection
  - Register/Forgot? for SignIn dialog
  - Scaling
    - See [Text.fontSizeMode](https://doc.qt.io/qt-5/qml-qtquick-text.html#fontSizeMode-prop)
  - Test HGlassRectangle elements when no effects are available
  - Add room
  - Leave room
  - Forget room warning popup
  - Prevent using the SendBox if no permission (power levels)
  - Spinner when loading past room events, images or clicking buttons
  - Better theming/styling system
    - See about <https://doc.qt.io/qt-5/qtquickcontrols2-configuration.html>
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
  - Don't send setTypingState False when focus lost if nothing in sendbox
  - Initial sync filter and lazy load, see weechat-matrix `_handle_login()`
    - See also `handle_response()`'s `keys_query` request
  - HTTP/2
  - `retry_after_ms` when rate-limited
  - Direct chats category
  - On sync, check messages API, if a limited sync timeline was received
  - Markdown: don't turn #things into title (space), disable __ syntax
  - Push instead of replacing in stack view
  - Make links in room subtitle clickable, formatting?
  - `<pre>` scrollbar on overflow
  - Handle cases where an avatar char is # or @ (#alias room, @user\_id)
  - When inviting someone to direct chat, room is "Empty room" until accepted,
    it should be the peer's display name instead.
  - Keep an accounts order
  - See `Qt.callLater()` potential usages
  - Banner name color instead of bold

- Missing nio support
  - Invite events are missing their timestamps
  - Left room events
  - `org.matrix.room.preview_urls` event
  - `m.room.aliases` event
  - Support "Empty room (was ...)" after peer left

- Waiting for approval/release
  - nio avatars
  - olm/olm-devel 0.3.1 in void repos

- Distribution
  - Review setup.py, add dependencies
  - README.md
  - Use PyInstaller or pyqtdeploy
    - Test command:
    ```
    pyinstaller --onefile --windowed --name harmonyqml \
                --add-data 'harmonyqml/components:harmonyqml/components' \
                --additional-hooks-dir . \
                --upx-dir ~/opt/upx-3.95-amd64_linux \
                run.py
    ```
