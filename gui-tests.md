# Manual GUI tests

## Sidepane

All the following statements must be true.


For all tests:

- When the pane collapses, the overall spacing/margins/paddings is 0.
- When the pane expands, the spacing/margins/paddings are restored.


Shrink the window (default auto-sizing pane):

- Pane collapses and spacing reduces with an animation under a certain size.
- Pane disappears (reduces) under an even smaller size.


Expand the window (default auto-sizing pane):

- Pane reappears collapsed from its reduced state above a certain size.
- Pane expands from its collapsed state above a even larger size.
- Pane stop growing past a certain even larger size.


Manually drag the pane to resizing. While dragging:

- Pane correctly collapses and expands when hitting the tresholds.
- Pane size can't go below the collapsed size.
- Pane size can't go above the minimum window content size (240 + margins).


Manually drag the pane to its minimum collapsed size:

- Pane never changes size no matter the window width, *except* to reduce
  when the window becomes too thin.


Manually drag the pane to its maximum grown size for the current window width:

- When shrinking the window, the pane stays to its maximum possible width
  while respecting the minimum window content size.
  It can still reduce if the window is too thin.

- After shrinking, when growing the window again, the pane grows until reaching
  the size it was previously given on manual drag, never more.


Shrink the window enough for the pane to be in reduced mode:

- In a page or room, a left-to-right swipe gesture shows a full-window pane.
- On the full-window pane, a right-to-left swipe goes back to the page/room.
- On the full-window pane, tapping on a room/page properly goes to it.
