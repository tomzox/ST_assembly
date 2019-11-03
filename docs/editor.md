# Editor (IDE)

This page describes my line-based text & printer-macro editor that I wrote for
Atari-ST mainly between 1986 and 1988. The program additionally has a limited
command "shell", allowing file & disk operations and running other programs.
Essentially I used it as "Integrated Development Environment" containing
everything I needed for software development:

 * Text editor
 * Shell for starting compilation/assembly
 * Shell for miscellaneous file & disk operations
 * Printer control ([Gemini Star](https://www.google.com/search?q=gemini+star+printer))
 * Alarm timer

The editor is a "TOS" program, which means it is based on the VT52 terminal
emulation. The program only supports high-resolution mode with 80 characters
per line.

## What's a "Line Editor"?

You can find a good description of
["Line editor" in Wikipedia](https://en.wikipedia.org/wiki/Line_editor):
> In computing, a line editor is a text editor in which each editing command
> applies to one or more complete lines of text designated by the user. Line
> editors predate screen-based text editors and originated in an era when a
> computer operator typically interacted with a teleprinter (essentially a
> printer with a keyboard), with no video display, and no ability to move a
> cursor interactively within a document. Line editors were also a feature of
> many home computers, avoiding the need for a more memory-intensive full-screen
> editor.

Indeed the concepts used here are inspired by the editor of Commodore Basic
and a line editor I believe was called "Dandit" which I used on terminals
connected to a [CDC Cyber mainframe](https://en.wikipedia.org/wiki/CDC_Cyber)
when working as an Intern ("Ferienhilfe") at Siemens 1985.

The concept used here is extended however to support input of binary data
for printer control sequences.  Therefore one level of indirection is added
by having all plain text assigned to a line within quotes. Besides text in
quotes there can be numeric values or macros that map to printer control codes.
The different types can be mixed within a line, separated by comma.


## Key bindings

This section lists all special keys understood by the editor. As you can see,
the editor does not have commands directly bound to keys (except if assigned to
function keys). Instead most of the following keys help edit the characters on
screen. After changing the content on screen, you can enter the content of one
line as a command by pressing the Return key.  In particular, for editing
content you would first list a number of lines on screen (see next section),
then use the following to make changes to the lines.  For each modified line
you need to press Return within that line to update it in memory - else the
changes have no effect. You could also edit the line number in front of the
screen line to assign the content to a different line in the text buffer.

|Key    | Action |
|:------|:-------|
| up/down/left/right | Move the cursor in the respective direction, possibly wrapping at screen borders (i.e. not scrolling) |
| Backspace | Moves the cursor one column to the left and replaces that character with blank. (Note in contrary to `Del` the line to the right of the cursor is not moved. |
| Del  | Deleted the character under the cursor and moves the rest of the line left by one, so that last character in the line is blank. |
| Insert | Shifts all characters starting with the cursor position one to the right, discarding the last character in the list. The character under the cursor is blank. |
| Home | Moves the cursor into the upper-left corner. |
| Shift-Home | Clears the screen and moves the cursor into the upper-left corner. |
| Tab | Moves the cursor to the next tabulator, as configured by command `SET TABS`. Line content is unmodified. |
| Escape | Prints "ESC" to the screen. |
| Shift-F1 | Pops up a text box showing the decimal ASCII code of the character under the cursor, until SHIFT is released. |
| Help+Del | Delete the content of the line containing the cursor and scroll the following lines up. |
| Help+Ins | Scrolls the content of the screen beginning witht he line containing the cursor down and inserts a blank line. |
| Help+Home | Blanks the line containing the cursor and moves the cursor to the first column. |
| Help+Up | Blanks the screen from upper-left corner up to the cursor position. |
| Help+Down | Blanks the screen from the cursor position down to the lower-right corner. |
| Help+Right | Blanks the line starting at the cursor position to the end of the line. |
| Help+Left | Blanks the line from the left of the screen up to the current the cursor position (included). |
| F1    | Waits for another function key to be pressed, then assigns the following key sequence to the key until the same function key is pressed. |
| F2-F10 | Plays back a key sequence previously assigned via F1 as described above. |
| Return | Evaluates the content of the screen line containing the cursor as an editor command (see next section). Notably command evaluation only users characters typed in by the user, or output from the `LIST` command; output from other commands is considered like blank. |

Any other key will echo the corresponding character to the current cursor position and move the cursor one to the right, possibly wrapping to the next line; in case of the latter, when in the last line of the screen, the screen is scrolled up by one line. Notably the character at the current cursor position is overwritten.

## Function keys

To make the editor usable, it's essential to assign commands to function keys
(using `F1`, as described in the previous section). The following commands are
pre-defined:

|Key    | Assigned sequence | Description |
|:------|:------------------|:------------|
| F2    | `CR LF '` Left Left Left Return| Closes current line with CR-LF and quote signs, then sends Return to assign it to the text buffer. |
| F9    | Help Pos1 `LIST P22-C` Return | Clear screen and list previous 22 lines. |
| F10   | Help Pos1 `LIST C-N22` Return | Clear screen and list next 22 lines. |

## Commands

This section lists commands understood by the program, grouped by purpose.
Commands are entered by typing the command words and parameters listed below in
a screen line and then pressing return. This implies a command cannot span more
than one screen line.

Generally, when commands require parameters, they need to be separated by space
from the command. In case the command takes multiple parameters, these are
separated by comma; optionally there may be space before or after the comma.
When entering an unknown command or unexpected parameters the editor will
only print "Syntax error" without specifying further details.

### Commands related to the text editor

|Command| Parameters | Description   |
|:------|:-----------|:--------------|
| LOAD  | filename [,line] | Loads content of the given file. The command automatically detects the file format: <UL><LI>Files created by `SAVE` are loaded exactly as stored, i.e. line numbering and quoting is preserved. Except, if the buffer is not empty then line numbers are appended in 10-stepping after the last line in the buffer. If a line number is given, this nunmber is used for the first line instead. If a loaded line would collide with a line already in the buffer, the command emits an error and aborts; already loaded lines remain in the buffer.<LI>For files in other formats, lines are created in 10-steps starting with the given line number, or starting after the last line already in the buffer if none given. All content is assigned within quotes (i.e. even special characters suchas CR/LF). New lines are started after LF, or after 72 characters which is the maximum length of a line (defined by the screen width as line assignment has to fit into a line).</UL> As implied above, there is no check if content of this file was already loaded. Note binary files can be loaded and viewed; however as non-printable characters are replaced by space during display, the content cannot be edited. (It is however possible to *create* binary files by using macros.) |
| SAVE  | filename  [,linespec]  | Saves the lines in a proprietary format, thus preserving line numbering and quotes. |
| CREATE | filename [,linespec] | Writes the content of the given lines into the given file. This means in particular that any printer macros such as "CR" are replaced with their assigned character sequence. Characters within quotes are copied verbatim. Note it's not allowed to use internal commands such as "list" (i.e. this is not intended for batch scripting.) |
| TEST | [linespec [,linespec...]] | Checks the given lines if they can be used for "CREATE" or "PRINT", i.e. checks if the lines contain a comma-separated list of macros or text within quotes. |
| NEW   | | Discards the entire content of the buffer. Should ask for confirmation if the current content was not saved after modifications. |
| FREE  | | Prints the memory in bytes that is available for line storage. Note each line requires management overhead (such as line number, and mark-up for quotes etc.), so actual content that can be stored is significantly less. |
| QUIT  | | Quits the program. Asks for confirmation if there are unsaved changes to the text buffer. |
|<hr>|<hr>|<hr>|
| number| non-empty | Assigns the given content to the given line number. If the same line number is already used, it is replaced with the given text. Line numbers must be in range 1 to 65535. The command performs no syntax checking on the assigned content (see also command "TEST"). |
| LIST | linespec [,linespec...] | Lists all lines with numbers in the given ranges. See definition of line number specifications below. The listing can be controlled via status keys: SHIFT temporarily halts; CONTROL slows down; ALTERNATE aborts. |
| L |  | Equivalent to "LIST". |
| FIND | text [[,]linespec] | Lists all lines within the given range (or the complete buffer) that contain the given string, case-insensitive. The listing can be controlled via modifier keys, equivalently to LIST. |
| FINDWORD | text | Same as FIND, but ignoring case. |
| REPLACE | text, subst [,linesspec] | Replaces all occurrences of "text" within the given range of lines. |
| REPLACEWORD | | Equivalent "REPLACE" but ignoring case. |
| RENUM | [start [,delta]] | Renumbers all lines in the buffer to start with the given number and consecutive delta. When omitted both values default to 10. Note this command is a shortcut for "MOVE f-l, start, delta". |
| DELETE | linespec [,linespec...] | Deletes the given ranges of lines from the buffer. |
| MOVE | linespec ,line [,delta] | Moves the given range of lines, to start at the second line number, spaced with the given line number delta (or 10 if no delta is given). An error occurs if there are pre-existing lines (other than the moved lines) overlapping or in-between the target number range (in that case lines are not moved, but remain renumbered with delta 1 starting at the source line number.) In case of success, the commands prints the number of lines that have to be moved in memory (i.e. if there were other lines in range between the given source range and the target range); The number is zero if the move involved only renumbering. |
| COPY | linespec ,line [,delta] | Copies the given range of lines and inserts them starting at the given line number with the given delta (or 10 if not given). An error occurs if there are pre-existing lines overlapping the line number range required by the new lines. (In error case only the lines that fit are copied, the others are omitted. Note you can use `RENUM` to make space.) In case of success, the command prints the number of lines that were copied. |
|<hr>|<hr>|<hr>|
| SET TABS | [number [,number...]] | Sets tabulators at the given columns, if any. Thus when prssing the TAB key, the cursor will be placed to the next of the given columns, or the start of the next line. |
| GUIDE | | Prints a ruler indicating the currently configured TAB stops. |

### Commands related to files and disk

The following commands directly map to respective GEMDOS or XBIOS functions.

|Command| Parameters | Description   | GEMDOS / XBIOS |
|:------|:-----------|:--------------|:---------------|
| EXE   | executable name [,Comma-separated parameters...] | Starts the given executable with the given parameters. Before the program is started the editor buffer is cleared to release memory for the other application (there is a warning if there are unsaved changes). You should only start TOS programs this way; output printed by the commands is left on screen after exit, however grayed out. The exit status of the program is ignored, except for errors generated by GEMDOS. | [Pexec](https://freemint.github.io/tos.hyp/en/gemdos_process.html#Pexec) |
| DRIVE | drive letter | Changes the current drive to the one indicated by the letter. | [Dsetdrv](https://freemint.github.io/tos.hyp/en/gemdos_directory.html#Dsetdrv) |
| CD    | path | Changes working directory to the given path. Following file commands (including editor `LOAD` et.al.) that do not specify absolute paths will be relative to this path. | [Dsetpath](https://freemint.github.io/tos.hyp/en/gemdos_directory.html#Dsetpath) |
| GET DIR | | Prints the working directory of the current drive. | [Dgetpath](https://freemint.github.io/tos.hyp/en/gemdos_directory.html#Dgetpath) |
| DIR   | [pattern] | Lists the content of the current directory. If a pattern is given then only file names matching the pattern are listed (e.g. `DIR \*.TOS`) ||
| MKDIR | path | Creates a directory with the given path and name.| [Dcreate](https://freemint.github.io/tos.hyp/en/gemdos_directory.html#Dcreate) |
| RMDIR | | Removes a directory with the given path and name. | [Ddelete](https://freemint.github.io/tos.hyp/en/gemdos_directory.html#Ddelete) |
| ERA   | name | Erases the given file. Warning: The command does not ask for confirmation. | [Fdelete](https://freemint.github.io/tos.hyp/en/gemdos_file.html#Fdelete) |
| REN   | old, new name | Renamed file "old" into "new name". | [Frename](https://freemint.github.io/tos.hyp/en/gemdos_file.html#Frename) |
| MKLABEL | label | Creates a special file of type "volume label" with the given name, thus labeling the current disk drive with that name. | [Fcreate](https://freemint.github.io/tos.hyp/en/gemdos_file.html#Fcreate) |
| RMLABEL | | Removes the first file with volume label attribute found in the current directory. | [Fdelete](https://freemint.github.io/tos.hyp/en/gemdos_file.html#Fdelete) |
| FILETIME | name, time | Sets the modification time of the given file to the time given in format HH:MM. The modification date will remain unchanged. | [Fdatime](https://freemint.github.io/tos.hyp/en/gemdos_file.html#Fdatime) |
| FILEDATE | name, date | Sets the modification date of the given file to the time given in format HH:MM. The modification time will remain unchanged. | [Fdatime](https://freemint.github.io/tos.hyp/en/gemdos_file.html#Fdatime) |
| FILEMOD | name,mode | Changes the attributes of the given file to the given value. The value is a bitmask as defined by GEMDOS "Fattrib". Use value 0 to make the file writable, or value 1 to make it read-only. Other values should be used with care. | [Fattrib](https://freemint.github.io/tos.hyp/en/gemdos_file.html#Fattrib) |
| FORMAT | [:attributes] | Asks for confirmation and the formats the current drive with 10 sectors per track. If a parameter is given it must contain ":" and be followed by letters "F", "2", or both: The first asks to create a FAT file system on the fisk; the second asks for formatting both sides. | [Protobt](https://freemint.github.io/tos.hyp/en/xbios_drive.html#Protobt), [Flopfmt](https://freemint.github.io/tos.hyp/en/xbios_drive.html#Flopfmt) |
| INFO  | | Prints disk label and free space o the disk. | [Dfree](https://freemint.github.io/tos.hyp/en/gemdos_directory.html#Dfree) |
| VERSION | | Prints the GEMDOS version. | [Sversion](https://freemint.github.io/tos.hyp/en/gemdos_system.html#Sversion) |

### Commands related to time & alarm

|Command| Parameters | Description   |
|:------|:-----------|:--------------|
| ALARM | HH:MM[:SS] | Schedules for an alarm to be raised at the given time. The alarm is a gong that occurs every few seconds until stopped using the following command. |
| ALARM OFF | | This command switches off an ongoing alarm sound, if any. |
| TIME | | This command prints the current time of day in format "HH:MM:SS". |
| DATE | | This command print the current date in format DD.MM.YYYY |
| SET TIME | HH:MM[:SS] | This command sets the system clock to the given time. The values may be specified as single-digit. The date is unchanged. |
| SET DATE | DD.MM[.YYYY] | This command changes the date of the system clock to the given date. Day and month may be given as single-digit 0-9; the year may be omitted to keep the current value. The current time of day is unchanged. |

### Commands related to printer control

|Command| Parameters | Description   |
|:------|:-----------|:--------------|
| PRINT | [linespec] | Parses the given lines in the text buffer and sends the generated output to the printer. Parsing means that text within quotes is sent verbatim, but macros such as "CR" are replaced with their assigned character sequence. Therefore this command is equivalent `CREATE`, except that output is sent to the printer instead of a file. |
| LPRINT | linespec [,linespec...] | Prints all lines with numbers in the given ranges. See definition of line number specifications below. The command is equivalent `LIST` except that output is sent to the printer except to screen. This means in particular that output contains line numbers, text quotes and macro names (i.e. macros are not converted to binary). Be warned that if text within quotes contains character codes that are special to the printer, these are passed-through as is and may corrupt output. Equivalently to on-screen output, the listing can be controlled via status keys: SHIFT temporarily halts; CONTROL slows down; ALTERNATE aborts. |
| MODE ORIGINAL || Selects raw printing mode where all characters codes in the file are passed to the printer unchanged. |
| MODE TEXT || Selects a simple mapping suitable for Gemini Star. This is the default mode. |
| MODE XTEXT || Selects configurable mapping as defined by `MAKE`. |
| MAKE | num = num2 | Maps the first given character code to the second code when printing in "XText" mode. Only characters in ranges 0-31 and 128-255 can be mapped. |

Additionally any content that may get assigned to an editor line can be entered
without a preceding line number. In this case the corresponding characters are
sent directly to the printer. This means there can be single-quoted text, bare
numbers, or printer macros, separated by comma. Example:
```
    italic,'Important!',no italic,ff
```

List of macros:
CR, LF, ITALIC, NO ITALIC, CHAR SET, CPI 10, CPI 12, CPI 17, PICA, ELITE,
COMPRESSED, DOUBLE WIDE, NO DOUBLE WIDE, DOUBLE STRIKE, NO DOUBLE STRIKE, EMPHASIZE,
NO EMPHASIZE, UNDERLINE, NO UNDERLINE, SUPERSCRIPT, SUBSCRIPT, NO SCRIPT,
UNIDIRECT, BIDIRECT, FEED 6, FEED 8, FEED 72, FEED 144, FEED ONCE 144, FORM LINES,
FORM INCHES, HEADERLINES, SKIP OVER, NO SKIP OVER, VERTICAL TABS, FEED LINES,
LH MARGIN, RH MARGIN, HORIZONTAL TABS, BLANKS, DEFINE MACRO, END MACRO, MACRO,
DEFINE CHAR, SHIFT, NO SHIFT, COPY FONTS, DOWNLOAD, NO DOWNLOAD, ON LINE, OFF LINE,
BUZZER, NO BUZZER, PAPER OUT, NO PAPER OUT, RESET, NUL, BEL, BS,
HT, VT, FF, SO, SI, DC1, DC2, DC3, DC4, RS, DEL, NX.

Any of the commands communicating with the printer will try for 30 seconds and
then abort with time-out if there is no response at the parallel port.

## Linespec

This section describes the line-specification which is a parameter to several of the
commands listed above. The specification tells these commands on which lines of the
buffered text they shall operate.

A line-specification Comma-separated list of line number ranges. A range consists of a start and end line, separated by hyphen. Start and end can be numeric, or one of the following. Note if end is less than start the range is treated as empty (not an error).

| Syntax | Description   |
|:-------|:--------------|
| c | current line, i.e. last printed or modified. |
| nNUM | next line following the current line, or next but NUM line (so that "n1" is equivalent "n") |
| pNUM | line preceding the current line, or preceding but NUM line (so that "p1" is equivalent "p") |
| f | first line in the file |
| l | last line in the file |

