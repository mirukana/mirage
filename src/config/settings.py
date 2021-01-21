# pylint: skip-file
# flake8: noqa
# mypy: ignore-errors

class General:
    # When closing the window, minimize the application to system tray instead
    # of quitting the application.
    # A click on the tray icon reveals the window, middle click fully quits it
    # and right click opens a menu with these options.
    close_to_tray: bool = False

    # Show rooms, members and messages in way that takes less vertical space.
    compact: bool = False

    # When the window width is less than this number of pixels, switch to a
    # mobile-like mode where only the left main pane, center page/chat or
    # right room pane is visible at a time.
    hide_side_panes_under: int = 450

    # How many seconds the cursor must hover on buttons and other elements
    # to show tooltips.
    tooltips_delay: float = 0.5

    # Application theme to use.
    # Can be the name of a built-in theme (Mirage.qpl or Glass.qpl), or
    # the name (including extension) of a file in the user theme folder, which
    # is "$XDG_DATA_HOME/mirage/themes" if that environment variable is set,
    # else "~/.local/share/mirage/themes".
    # For Flatpak, it is
    # "~/.var/app/io.github.mirukana.mirage/data/mirage/themes".
    theme: str = "Midnight.qpl"

    # Interface scale multiplier, e.g. 0.5 makes everything half-size.
    zoom: float = 1.0

class Presence:
    # Automatically set your presence to unavailable after this number of
    # seconds without any mouse or keyboard activity.
    # This currently only works on Linux X11.
    auto_away_after: int = 60 * 10

class Notifications:
    # How long in seconds the window will flash in your dock or taskbar when
    # a new message, which matches a notification push rule with a
    # flash (lightbulb) action, is posted in a room.
    # The effect may differ depending on your OS/desktop.
    # or dock to be highlighted or to flash.
    # Can be set to -1 for alerts that last until the window is focused.
    flash_time: float = 5

    # Same as flash_time, but for messages that match a push rule with a
    # highlight (red [+1]) action. By default this includes when your
    # name is mentioned, replied to, or messages containing keywords.
    highlight_flash_time: float = -1

class Scrolling:
    # Use velocity-based kinetic scrolling.
    # Can cause problems on laptop touchpads and some special mouse wheels.
    kinetic: bool = True

    # Maximum allowed velocity when kinetic scrolling is used.
    kinetic_max_speed: int = 2500

    # When kinetic scrolling is used, how fast the view slows down when you
    # stop physically scrolling.
    kinetic_deceleration: int = 1500

    # Multiplier for the scrolling speed when kinetic scrolling is
    # disabled, e.g. 1.5 is 1.5x faster than the default speed.
    non_kinetic_speed: float = 1.0

class RoomList:
    # Prevent resizing the pane below this width in pixels.
    min_width: int = 144

    # Sort rooms in alphabetical order instead of recent activity.
    # The application must be restarted to apply changes for this setting.
    lexical_sort: bool = False

    # When any event is received in a room, mark the room as unread with a [!],
    # regardless of notification push rules. This does not take into account
    # anything received while the client is not running.
    local_unread_markers: bool = False

    # When clicking on a room, recenter the room list on that room.
    click_centers: bool = False

    # When pressing enter in the room filter field, clear the field's text,
    # in addition to activating the keyboard-focused room.
    enter_clears_filter: bool = True

    # When pressing escape in the room filter field, clear the field's text.
    # in addition to focusing the current page or chat composer.
    escape_clears_filter: bool = True

    class Bookmarks:
        # Each property in this section is an account user ID, and the
        # value is a list of room ID to always keep on top.
        # A room's ID can be copied by right clicking on it in the room list.

        "@account:example.org": List[str] = ["!roomID:a.org", "!other:b.org"]

class Chat:
    # Center the chat header (room avatar, name and topic) even when sidepanes
    # aren't hidden (see comment for the hide_sidepanes_under setting).
    always_center_header: bool = False

    # When the chat timeline is larger than this pixel number,
    # align your own messages to the left of the timeline instead of right.
    # Can be 0 to always show your messages on the left.
    own_messages_on_left_above: int = 895

    # Maximum number of characters in a message line before wrapping the text
    # to a new line. Ignores messages containing code blocks or tables.
    max_messages_line_length: int = 65

    # Show membership events in the timeline: when someone is invited to the
    # room, joins, leaves, is kicked, banned or unbanned.
    show_membership_events: bool = True

    # Show room member display name and avatar change events in the timeline.
    show_profile_changes: bool = False

    # Show a notice in the timeline for events types that aren't recognized.
    show_unknown_events: bool = False

    # In a chat with unread messages, the messages will be marked as read
    # after this number of seconds.
    # Focusing another window or chat resets the timer.
    mark_read_delay: float = 0.2

    class Composer:
        class TypingNotifications:
            # Rules controlling whether "<user> is typing..." notifications
            # should be sent to other users in rooms.
            # The `default` property is required. Other properties can be
            # added: user IDs, room IDs, or space-separated user + room IDs.

            # Send typing notifications everywhere by default:
            default: bool = True
            # But don't send them for rooms under this account:
            "@account_1:example.org": bool = False
            # Neither send them in this room, regardless of the account used:
            "!room:example.org": bool = False
            # Except if it's this account and this room, then send them:
            "@account_2:example.org !room:example.org": bool = True

        class Aliases:
            # Each property is the user ID of an account, value is the alias.
            # From any chat, start a message with an alias followed by a space
            # to type and send as the associated account.
            # The account must have permission to talk in the room.
            # To ignore an alias when typing, prepend it with a space.

            "!account:example.org":       str = "u"
            "!other_account:example.org": str = "oa"

    class Files:
        # Minimum width of the file name/size box for files without previews.
        min_file_width: int = 256

        # Minimum (width, height) for image thumbnails.
        min_thumbnail_size: Tuple[int, int] = (256, 256)

        # How much of the chat height image thumbnails can take at most,
        # e.g. 0.4 for 40% of the chat or 1 for 100%.
        max_thumbnail_height_ratio: float = 0.4

        # Automatically play animated GIF images in the timeline.
        auto_play_gif: bool = True

        # When clicking on a file in the timeline, open it in an external
        # programing instead of displaying it using Mirage's interface.
        # On Linux, the xdg-open command is used.
        click_opens_externally: bool = False

        # In the full image viewer, if the image is large enough to cover the
        # info bar or buttons, they will automatically hide after this number
        # of seconds.
        # Hovering on the top/bottom with a mouse or tapping on a touch screen
        # reveals the hidden controls.
        autohide_image_controls_after: float = 2.0

class Keys:
    # All keybind settings, unless their comment says otherwise, are list of
    # the possible shortcuts for an action, e.g. ["Ctrl+A", "Alt+Shift+A"].
    #
    # The available modifiers are Ctrl, Shift, Alt and Meta.
    # On macOS, Ctrl corresponds to Cmd and Meta corresponds to Control.
    # On other systems, Meta corresponds to the Windows/Super/mod4 key.
    #
    # https://doc.qt.io/qt-5/qt.html#Key-enum lists the names of special
    # keys, e.g. for "Qt::Key_Space", you would use "Space" in this config.
    #
    # The Escape key by itself should not be bound, as it would conflict with
    # closing popups and various other actions.
    #
    # Key chords can be defined by having up to four shortcuts
    # separated by commas in a string, e.g. for ["Ctrl+A,B"], Ctrl+A then B
    # would need to be pressed.

    # Helper functions

    import platform

    def os_ctrl(self) -> str:
        # Return Meta on macOS, which corresponds to Ctrl, and Ctrl on others.
        return "Meta" if platform.system() == "Darwin" else "Ctrl"

    def alt_or_cmd(self) -> str:
        # Return Ctrl on macOS, which corresponds to Cmd, and Alt on others.
        return "Ctrl" if platform.system() == "Darwin" else "Alt"

    # Toggle compact interface mode. See the compact setting comment.
    compact = ["Alt+Ctrl+C"]

    # Control the interface scale.
    zoom_in    = ["Ctrl++"]
    zoom_out   = ["Ctrl+-"]
    reset_zoom = ["Ctrl+="]

    # Switch to the previous/next tab in pages. In chats, this controls what
    # the right room pane shows, e.g. member list or room settings.
    previous_tab = ["Alt+Shift+Left", "Alt+Shift+H"]
    next_tab     = ["Alt+Shift+Right", "Alt+Shift+L"]

    # Switch to the last opened page/chat, similar to Alt+Tab on most desktops.
    last_page = ["Ctrl+Tab"]

    # Toggle the QML developer console. Type ". help" inside it for more info.
    qml_console = ["F1"]

    # Start the Python backend debugger.
    # Mirage must be connected to a terminal for this to work.
    python_debugger = ["Shift+F1"]

    # Start the Python backend debugger in remote access mode.
    # The remote-pdb Python package must be installed.
    # From any terminal, run `socat readline tcp:127.0.0.1:4444` to connect.
    python_remote_debugger = ["Alt+F1"]

    class Scrolling:
        # Pages and chat timeline scrolling
        up        = ["Alt+Up", "Alt+K"]
        down      = ["Alt+Down", "Alt+J"]
        page_up   = ["Alt+Ctrl+Up", "Alt+Ctrl+K", "PgUp"]
        page_down = ["Alt+Ctrl+Down", "Alt+Ctrl+J", "PgDown"]
        top       = ["Alt+Ctrl+Shift+Up", "Alt+Ctrl+Shift+K", "Home"]
        bottom    = ["Alt+Ctrl+Shift+Down", "Alt+Ctrl+Shift+J", "End"]

    class Accounts:
        # The current account is the account under which a page or chat is
        # opened, or the keyboard-focused one when using the room filter field.

        # Add a new account
        add = ["Alt+Shift+A"]

        # Collapse the current account
        collapse = ["Alt+O"]

        # Open the current account settings
        settings = ["Alt+A"]

        # Open the current account context menu
        menu = ["Alt+P"]

        # Toggle current account presence between this status and online
        unavailable = ["Alt+Ctrl+U", "Alt+Ctrl+A"]
        invisible   = ["Alt+Ctrl+I"]
        offline     = ["Alt+Ctrl+O"]

        # Switch to first room of the previous/next account in the room list.
        previous = ["Alt+Shift+N"]
        next     = ["Alt+N"]

        class AtIndex:
            # Switch to the first room of the account number X in the list.
            # Each property is a list of keybinds for the account number X.
            # Numbers beyond the default ones can be added.

            1  = [Keys.os_ctrl() + "+1"]
            2  = [Keys.os_ctrl() + "+2"]
            3  = [Keys.os_ctrl() + "+3"]
            4  = [Keys.os_ctrl() + "+4"]
            5  = [Keys.os_ctrl() + "+5"]
            6  = [Keys.os_ctrl() + "+6"]
            7  = [Keys.os_ctrl() + "+7"]
            8  = [Keys.os_ctrl() + "+8"]
            9  = [Keys.os_ctrl() + "+9"]
            10 = [Keys.os_ctrl() + "+0"]

    class Rooms:
        # Add a new room (direct chat, join or create a group).
        add = ["Alt+C"]

        # Focus or clear the text of the left main pane's room filter field.
        # When focusing the field, use Tab/Shift+Tab or the arrows to navigate
        # the list, Enter to switch to focused account/room, Escape to cancel,
        # Menu to open the context menu.
        focus_filter = ["Alt+F"]
        clear_filter = ["Alt+Shift+F"]

        # Switch to the previous/next room in the list.
        previous = ["Alt+Shift+Up", "Alt+Shift+K"]
        next     = ["Alt+Shift+Down", "Alt+Shift+J"]

        # Switch to the previous/next room with unread messages in the list.
        previous_unread = ["Alt+Shift+U"]
        next_unread     = ["Alt+U"]

        # Switch to the previous/next room with highlighted messages in the
        # list. What causes a highlight is controlled by push rules
        # (editable in GUI account settings): by default, this includes
        # when your name is mentioned, replied to, or messages with keywords.
        previous_highlight = ["Alt+Shift+M"]
        next_highlight     = ["Alt+M"]

        class AtIndex:
            # Switch to room number X in the current account.
            # Each property is a list of keybinds for the room number X:
            # Numbers beyond the default ones can be added.

            1  = [Keys.alt_or_cmd() + "+1"]
            2  = [Keys.alt_or_cmd() + "+2"]
            3  = [Keys.alt_or_cmd() + "+3"]
            4  = [Keys.alt_or_cmd() + "+4"]
            5  = [Keys.alt_or_cmd() + "+5"]
            6  = [Keys.alt_or_cmd() + "+6"]
            7  = [Keys.alt_or_cmd() + "+7"]
            8  = [Keys.alt_or_cmd() + "+8"]
            9  = [Keys.alt_or_cmd() + "+9"]
            10 = [Keys.alt_or_cmd() + "+0"]

    class Chat:
        # Keybinds specific to the current chat page.

        # Focus the right room pane. If the pane is currently showing the
        # room member list, the corresponding filter field is focused.
        # When focusing the field, use Tab/Shift+Tab or the arrows to navigate
        # the list, Enter to see the focused member's profile, Escape to cancel,
        # Menu to open the context menu.
        focus_room_pane = ["Alt+R"]

        # Toggle hiding the right pane.
        # Can also be done by clicking on current tab button at the top right.
        hide_room_pane = ["Alt+Ctrl+R"]


        # Invite new members, leave or forget the current chat.
        invite = ["Alt+I"]
        leave  = ["Alt+Escape"]
        forget = ["Alt+Shift+Escape"]

        # Open the file picker to upload files in the current chat.
        send_file = ["Alt+S"]

        # If your clipboard contains a file path, upload that file.
        send_clipboard_path = ["Alt+Shift+S"]

    class Messages:
        # Focus the previous/next message in the timeline.
        # Keybinds defined below in this section affect the focused message.
        # The Menu key can open the context menu for a focused message.
        previous = ["Ctrl+Up", "Ctrl+K"]
        next     = ["Ctrl+Down", "Ctrl+J"]

        # Select the currently focused message, same as clicking on it.
        # When there are selected messages, some right click menu options
        # and keybinds defined below will affect these messages instead of
        # the focused (for keybinds) or mouse-targeted (right click menu) one.
        # The Menu key can open the context menu for selected messages.
        select = ["Ctrl+Space"]

        # Select all messages from point A to point B.
        # If used when no messages are already selected, all the messages
        # from the most recent in the timeline to the focused one are selected.
        # Otherwise, messages from the last selected to focused are selected.
        select_until_here = ["Ctrl+Shift+Space"]

        # Clear the message keyboard focus.
        # If no message is focused but some are selected, clear the selection.
        unfocus_or_deselect = ["Ctrl+D"]

        # Toggle display of the focused message's seen counter tooltip,
        # which shows which user have this message as their last seen and when
        # did they send that information.
        # When this mode is active, you can move the focus to other messages
        # and the tooltip will update itself.
        # If a message doesn't have a counter, it won't have a tooltip.
        seen_tooltips = ["Ctrl+S"]

        # Remove the selected messages if any, else the focused message if any,
        # else the last message you posted.
        remove = ["Ctrl+R", "Alt+Del"]

        # Reply/cancel reply to the focused message if any,
        # else the last message posted by someone else.
        # Replying can also be cancelled by pressing Escape.
        reply = ["Ctrl+Q"]

        # Open the QML developer console for the focused message if any,
        # and display the event source.
        debug = ["Ctrl+Shift+D"]

        # Open the files and links in selected messages if any, else the
        # file/links of the focused message if any, else the last
        # files/link in the timeline.
        open_links_files = ["Ctrl+O"]

        # Like open_links_files, but files open in external programs instead.
        # On Linux, this uses the xdg-open command.
        open_links_files_externally = ["Ctrl+Shift+O"]

        # Copy the downloaded files path in selected messages if any,
        # else the file path for the focused message if any, else the
        # path for the last downloaded file in the timeline.
        copy_files_path = ["Ctrl+Shift+C"]

        # Clear all messages from the chat.
        # This does not remove anything for other users.
        clear_all = ["Ctrl+L"]

    class ImageViewer:
        # Close the image viewer
        close = ["X", "Q"]

        # Toggle alternate image scaling mode: if the original image size is
        # smaller than the window, upscale it to fit the window.
        # If it is bigger than the window, show it as its real size.
        expand = ["E"]

        # Toggle fullscreen mode.
        fullscreen = ["F", "F11", "Alt+Return", "Alt+Enter"]

        # Pan/scroll the image.
        pan_left  = ["H", "Left", "Alt+H", "Alt+Left"]
        pan_down  = ["J", "Down", "Alt+J", "Alt+Down"]
        pan_up    = ["K", "Up", "Alt+K", "Alt+Up"]
        pan_right = ["L", "Right", "Alt+L", "Alt+Right"]

        # Control the image's zoom. Ctrl+wheel can also be used.
        zoom_in    = ["Z", "+", "Ctrl++"]
        zoom_out   = ["Shift+Z", "-", "Ctrl+-"]
        reset_zoom = ["Alt+Z", "=", "Ctrl+="]

        # Control the image's rotation.
        rotate_right   = ["R"]
        rotate_left    = ["Shift+R"]
        reset_rotation = ["Alt+R"]

        # Control the speed for animated GIF images.
        speed_up    = ["S"]
        slow_down   = ["Shift+S"]
        reset_speed = ["Alt+S"]

        # Toggle pausing for animated GIF images.
        pause = ["Space"]

    class Security:
        # These keybinds affect the Security tab in your account settings.
        #
        # Currently unchangable keys:
        # - Tab/Shift+Tab to navigate the interface
        # - Space to check/uncheck a focused session
        # - Menu to open the focused session's context menu

        # Refresh the list of sessions.
        refresh = ["Alt+R", "F5"]

        # Sign out checked sessions if any, else sign out all sessions.
        sign_out = ["Alt+S", "Delete"]
