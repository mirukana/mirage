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

- Load previous events on scroll up

- Migrate more JS functions to their own files
