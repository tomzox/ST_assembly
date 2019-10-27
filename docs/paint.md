# TH-Paint

This is a painting progam I wrote for my Atari-ST in MC-68000 assembly in
1987-1988.

## Drawing Tools (Shapes)

The `Shapes` menu is used to select the drawing tool. For drawing you first
need to open a new window (via the File menu, see next chapters).  Then a mouse
click into the window applies the tool. For many of the shapes you need to keep
the mouse button pressed and drag it, namely for defining the dimension of the
drawn object.

In general, each shape has a configuration dialog in the `Attributes` menu.
Enabling of filling and border drawing is done via the checkmarks in the Shapes
menu directly. This is covered in detail in the following table.

| Shape | Description |
|:------|:------------|
| Pencil | |
| Brush | |
| Spraycan | |
| Floodfill | |
| Text | |
| Eraser | |
| Rubberband | |
| Line | |
| Rectangle | |
| Square | |
| Polygon | |
| Circle | |
| Elipsis | |
| Curve | |

## Working with selections

To start a selection first check `Select region` in the `Selection` menu. Then
by clicking and dragging the mouse in the image window you can select a
rectangle as selected area. The rubberband rectangle will remain when you
release the mouse button to keep the area marked (but it is not part of the
image). Once a selection is done, all the selection commands in the `Selection`
menu become enabled.

| Operation | Description |
|:----------|:------------|
| Paste | |
| Discard | |
| Commit | |
| Erase | |
| Fill black | |
| Invert | |
| Mirror | |
| Rotate | |
| Zoom | |
| Distort | |
| Projection | |

The remaining three entries are options. They do not modify the selection
area directly, but rather change the way selection operates:

| Option    | Description |
|:----------|:------------|
| Copy | |
| Combine | |
| Overlay Mode | |

## Undo operation

TH-paint supports undoing only the very last drawing operation. When using
`Undo` in the File menu a second time, the change is re-applied. Also note
that changing between windows will clear the undo buffer (as there is only
a single such buffer shared by all windows).

## File operations

| Operation | Description |
|:----------|:------------|
| Undo | |
| Dicard image | |
| New window | |
| Load image | |
| Save as | |
| Save | |
| Print | |
| Quit | |

## Additional tools

| Operation | Description |
|:----------|:------------|
| Save coordinates | |
| Coordinates | |
| Zoom view | |
| Full-screen mode | |
| Cross mouse shape | |
| Show mouse coordinates | |
| Snap to grid | |
| Grid setup | |
