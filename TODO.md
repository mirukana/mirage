- Current focus
  - When clicking on invited room but no multiaccount broadcasting events
  - Sort accounts
  - Merge login page

- Refactoring
  - Set Qt parents for all QObject
  - Migrate more JS functions to their own files / Implement in Python instead
  - Don't bake in size properties for components
  - Better names and organization for the Message components

- Bug fixes
  - Graphic bug when resizing window vertically for side pane?
  - Fix tooltip hide()
  - ![A picture](https://picsum.photos/256/256) not clickable?
  - Icons aren't reloaded

- UI
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

- Missing nio support
  - Forget room
  - Left room events
  - `org.matrix.room.preview_urls` event
  - `m.room.aliases` event
  - Avatars
  - Support "Empty room (was ...)" after peer left
