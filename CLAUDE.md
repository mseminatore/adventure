# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

"Mystery Mansion" — a text adventure game written in 6809 assembly for the TRS-80 Color Computer (CoCo). The entire game (parser, world model, and content) lives in `adventure.asm`, assembled into a raw binary and packaged onto a bootable `.DSK` disk image that runs in a CoCo emulator (or on real hardware).

## Build

Requires two external tools, both from the same author, cloned as sibling directories to this repo:
- `as09` — the 6809 assembler (github.com/mseminatore/as09)
- `dsktools` (`dsk_new`, `dsk_add`, `dsk_del`) — CoCo disk image utilities (github.com/mseminatore/dsktools)

`./setup.sh` clones, builds, and installs both tools (into `/usr/local/bin`), then does a full build. Only needed once per machine.

```sh
make new       # create a fresh, empty ADV.DSK
make package   # add loader.bas (the BASIC bootstrap) to the disk, once
make           # assemble adventure.asm -> adv.bin, then replace it on ADV.DSK
make clean     # remove adv.bin and ADV.DSK
```

Normal edit/build/test loop is just `make` — it reassembles `adventure.asm` and refreshes the binary already on `ADV.DSK` (`dsk_del` + `dsk_add`). `make new` and `make package` are one-time disk-image setup steps, not part of the regular loop.

There is no automated test suite; testing is manual, by running the game (see below).

## Running / manual testing

Load `ADV.DSK` in the xroar-online emulator (https://colorcomputerarchive.com/xroar-online/) or another CoCo emulator: upload the disk, then power-cycle/reset. The loader (`loader.bas`, already on the disk via `make package`) does `LOADM "ADV.BIN"` + `EXEC` to run `adv.bin`. Re-upload `ADV.DSK` after every `make`.

## Architecture

### Source layout

- `adventure.asm` — everything: game loop, command parser, room/item/door logic, and all game *content* (room descriptions, item tables, door tables, room graph, rules, string literals). This is where almost all changes happen.
- `stddefs.inc` — hardware/ROM constants (CoCo ROM vectors, PIA registers, char codes, memory map/stack layout).
- `gamedefs.inc` — game-specific constants: struct field offsets and sizes for every table type below, item property bit flags, damage values, carry-limit constants.
- `io.inc` — low-level terminal I/O: cursor/video RAM handling, `CLS`, `PUTC`/`PUTS` (with word-wrap), `GETC`/`GETS` (line input).
- `print.inc` — number formatting (`PRINT_DEC_BYTE`, `PRINT_DEC_WORD`, `PRINT_HEX_BYTE/WORD`).
- `string.inc` — C-string helpers (`STRLEN`, `STRCHR`, `STREQ`, `STRCPY`); strings are null-terminated (`FCZ` in the assembler).
- `math.inc` — `DIVMOD`/`DIVMOD16` (byte/word divide), `RND8`/`RND16` PRNGs (`RND16` is currently stubbed out/commented — see note below).
- `loader.bas` — 3-line BASIC bootstrap that loads and execs the assembled binary from disk.

### Runtime model: a table-driven world, walked by a small interpreter

The game loop (`GAME_LOOP` in `adventure.asm`) is: run rules → describe room → read a line of input → dispatch a command → repeat. Almost all game *content* — not just data, but branching logic — is expressed as tables of pointers that the engine walks generically. When adding content (a new room, item, door, or rule), you are almost always adding a table row, not writing new code.

The key tables (struct layouts defined in `gamedefs.inc`, all terminated by a `NULL`/0 sentinel entry, all walked with the same "load ptr, compare to NULL, advance by struct size" loop pattern):

- **`ROOMS`** — one entry per room: description string ptr, then N/S/E/W neighbors. Each neighbor slot is either another room number, `-1` (no exit), or a pointer into `DOORS` (values > 255 are treated as door pointers, disambiguated from room numbers by `CMPD #255 / BLS`). Current room is the single global `ROOM` byte; `GET_ROOM_PTR` computes `ROOMS + ROOM*ROOM_SIZE`.
- **`DOORS`** (`DOOR1`, `DOOR2`, ...) + **`DINSTn`** (door *instances*) — a door table entry points at a shared door-instance record (description, lockable/open/locked property bits, required key item) plus the room number on the far side. Multiple `DOORn` entries share one `DINSTn` so both sides of a door reflect the same open/locked state.
- **`ITEMS`** — description ptr, current location (room number, or `CARRYING`/`$FF`, or `ROOM_DUMP`), a "read" text ptr (for `EXAMINE`/`READ`), and property bit flags (`TAKEABLE`, `EATABLE`, `DRINKABLE`, `USABLE`, `OPENABLE`, `LOCKABLE`, `DROPPABLE`, `FOUND_ITEM`) — `NORMAL_ITEM` = `TAKEABLE|DROPPABLE`.
- **`DECORATIONS`** — extra flavor-text snippets shown per room in addition to the main room description (e.g. wall sconces, compass-direction hints), matched by room number.
- **`RULES`** — pairs of (predicate fn, action fn), evaluated every turn in `CHECK_RULES`: if the predicate returns non-zero (Z clear), the action runs. Used for things like recalculating carry-item limits when the player has a sack/backpack (`HAVE_SACK`/`SET_ITEMS_SACK`, etc.).
- **`TRANSITIONS`** — (action fn, from-room, to-room) triggers fired by `CHECK_TRANSITION` on room movement, for one-off scripted events tied to a specific room edge (falling through a floor, entering/exiting an elevator or dumbwaiter, a balcony scene).
- **`CMDS`** — the verb table: first two characters of the input word mapped to a handler function pointer (e.g. `"GE"`/`"TA"`/`"GR"` all map to `GET_CMD`). Dispatch (`DO_CMD`) does a linear scan comparing the first 2 input chars against this table. There's also debug-only entries (`FO`, `RO`, `HO`, `RP`, `IT`) left in the table for development. A separate `CMD_TABLE`/`JMP_TABLE` pair exists for a token-based approach but appears to be legacy/unused compared to `CMDS`.

### Struct-offset convention

Every table's field offsets are named constants in `gamedefs.inc` (e.g. `ITEM_LOC_OFFSET`, `DOOR_ROOM_OFFSET`, `RULE_ACTION_OFFSET`) and record sizes are `*_SIZE` constants (e.g. `ROOM_SIZE`, `ITEM_SIZE`, `DOOR_SIZE`). Always use these symbolic offsets/sizes rather than hardcoding byte counts, and keep them in sync if a struct layout changes — code throughout `adventure.asm` indexes into these tables by offset (e.g. `LDA ITEM_LOC_OFFSET,Y`).

### Known incomplete area

`RND16` in `math.inc` is commented out (stubbed), while `RND8` is implemented (linear-congruential-ish: seed * 33 mod 251). If work touches randomness, check whether `RND16` needs finishing rather than assuming it works.
