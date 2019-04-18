- Separate categories for invited, group and direct rooms
- Invited → Accept/Deny dialog
- Keep the room header name and topic updated
- Merge login page
- Show actual display name for AccountDelegate

- When inviting someone to direct chat, room is "Empty room" until accepted,
  it should be the peer's display name instead.
- Support "Empty room (was ...)" after peer left

- Catch network errors in socket operations

- Proper logoff when closing client

- Handle cases where an avatar char is # or @ (#alias room, @user\_id)

- Use Loader? for MessageDelegate to show sub-components based on condition
- Better names and organization for the Message components

- Migrate more JS functions to their own files

- Accept room\_id arg for getUser

- Set Qt parents for all QObject

- `<pre>` scrollbar on overflow

- Make links in room subtitle clickable, formatting?

- Push instead of replacing in stack view

- QQuickImageProvider, matrix preview API

- Spinner when loading past room events or images

- nio: org.matrix.room.preview\_urls, m.room.aliases

- Markdown: don't turn #things into title (space), disable __ syntax
