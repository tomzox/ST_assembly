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
release the mouse button to keep the area marked (but it does not become part
of the image). Once a selection is done, all the selection commands in the
`Selection` menu become enabled. The selection is ended either by clicking
with the mouse outside of the selection frame, or by selecting a different
shape from the shapes menu.

The most basic operation on selections is moving them. To do so click with
the mouse anywhere within the selected region and drag it. The specific behavior
depends on the options described below.

| Operation | Description |
|:----------|:------------|
| Paste | Inserts a copy of the last selected area within a selection frame. |
| Discard | Discards the selection frame including its content, thus making the background below the selection visible. |
| Commit | This command is only available when a combination mode is enabled, or while the selection frame is cut off at a window border. In these cases this command copies the current size or combined content into the selection overlay. (This is equivalent to ending the selection and the selecting the exact same region again. |
| Erase | Fill the selection frame with white color. |
| Fill black | Fill the selection frame with black color. |
| Invert | Invert the content of the selection frame. |
| Mirror | Mirrors the content of the selection frame along a vertical or horizontal axis. |
| Rotate | Rotates the selection frame. The result is inserted in the middle of the window in a resized frame. |
| Zoom | Scales the selection frame and content by given factors in X And Y axis. In fixed mode the result is inserted as a resized selection frame in the middle of the window. In manual mode there is a switch into full-screen mode, where you can determine the desired scale by dragging the mouse. |
| Distort | In the simplest mode, the selection frame is slanted horizontally or vertically, but there are several more functions. More specifically, each line or row of pixels in the selection frame is shifted by an amount of pixels which is determined by a function (e.g. a linear function in case of the basic slant.) |
| Projection | This feature is not implemented yet. It was intended to allow projecting the selection content onto the surface of various geometric shapes and render a 2D view onto these shapes. |

The remaining three entries are options. They do not modify the selection
area directly, but rather change the way selection operates:

| Option    | Description |
|:----------|:------------|
| Copy | When enabled, the selected area is not cleared when a selection is started. Therefore a copy of the selected area is both in the background layer and in the selection layer. This may be useful when copying many parts of the image. It also is useful when working with combination modes, for example to create a shadow effect by using XOR and moving the image a small X/Y delta. |
| Combine | Open a dialog where you can select combination modes between selection frame content and the background layer (i.e. the rest of the image on top of which the selection frame resides). By default the selection is opaque. In all other modes the content of the selection frame changes whenever you move it. Note in overlay mode the result of combination is not copied to the selection layer, which means the actual selection content remains unchanged until you end the selection; at that time the result of the last combination is copied into the image. |
| Overlay Mode | This option is enabled by default. When *enabled* and a selection is started, the selected region of the image is cut out of the image and copied into a separate layer. When the selection frame is moved or otherwise modified, the rest of the image is not affected. Only when the selection is ended the selection frame content is copied into the image. When *disabled* the selection content is copied back into the image immediately after moving it (i.e. upon releasing the mouse button) or after any transformation. This is useful only in special cases, such as when working with combination modes such as XOR. |

## Undo operation

TH-paint supports undoing only the very last drawing operation. When using
`Undo` in the File menu a second time, the change is re-applied. Also note
that changing between windows will clear the undo buffer (as there is only
a single such buffer shared by all windows).

## File operations

| Operation | Description |
|:----------|:------------|
| Undo | As explained above, this command undoes or redoes the last change to the image in the current window. |
| Discard image | Clear the content of the current window. This command asks for confirmation if the content was modified. |
| New window | Open a new, empty window. This is usually the first used command after starting the program. |
| Load image | Load an image from a file. Supported formats are LOGO format, DEGAS format, or a raw format written by TH-Paint by default. The first two formats are automatically detected (due to lack of a header the raw format cannot be detected; you are able to load any kind of file as an image). |
| Save as | Store the image of the current window into a file. A dialog is opened to query for a file name. By default a raw format is used that stores the image row by row as a stream of pixels. The size of the stored image and other image formats can be selected in the Attributes menu. |
| Save | This command is enabled when the image was loaded from a file, or already stored via "Save as". The command stores the image to the same file, but still asks to confirm overwriting it. Note the file format is not rememberd from the time of loading the file, so the command defaults to raw mode unless a different format is selected in the Attributes menu. |
| Print | This command sends the image to a printed. The print can be stopped by pressing the ALT key. Note while printing other functions of the program cannot be used. Before using this command you'll normally want to configure the output using the respective dialog in the attributes menu. You can select between portrait and landscape orientation, as well if only parts of the image shall be printed. For some printers you may also need to apply a scaling to preserve the aspect ratio; for this purpose it's supported to stretch the image in printing direction by factor 1.5 or 2. |
| Quit | Terminate the program. The command asks for confirmation if the content of any windows was modified. |

## Additional tools

| Operation | Description |
|:----------|:------------|
| Save coordinates | Checking this option disables the current drawing shape or selection. Otherwise nothing will happen; likely this feature was not implemented yet. |
| Coordinates | This feature is not implemented yet, although the command opens a dialog asking for entering a number of coordinates depending on the currently selected drawing shape (but after doing so nothing will happen). It was intended to allow drawing shapes such as lines or rectangle with manually specified coordinates instead of using the mouse. |
| Zoom view | This feature is not implemented yet. It was intended for allowing to zoom the view of the image. |
| Full-screen mode | TH-Paint supports a full-screen mode where you can draw without the constraint of window borders and menu. You can quickly toggle between normal and full-screen mode by clicking into a window with the right mouse button. The menu command only displays a note pointing out this option. |
| Cross mouse shape | When this option is checked, the mouse shape has the form of a cross instead of the default pointer. The cross may be helpful when you need to precisely hit a pixel. |
| Show mouse coordinates | When this option is checked, the mouse coordinates are constantly displayed in the right corner of the menu bar. The coordinates are relative to the root of the image in the current window. When the mouse is moved outside of an image window only dashes are shown. |
| Snap to grid | When this option is checked, the mouse position is rounded to the closest position in the grid for all operations (without actually moving the mouse pointer to this position). This is useful for alinging start and end of multiple drawing operations. It can also be used for creating effects with freestyle tools such as the pencil (e.g. a stair effect when drawing diagonally). |
| Grid setup | Allows configuring the grid spacing as well as the grid origin. |
