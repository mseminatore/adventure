# adventure

This is a retro text adventure game written in 6809 assembly for the TRS-89 Color Computer. This project was 
started as a test case for two of my earlier projects: a 6809 assembler [as09](https://github.com/mseminatore/as09) and a virtual disk tool [dsktools](https://github.com/mseminatore/dsktools).

You can run the ADV.DSK image using XROAR running locally or web-hosted. Or, if you have your own TRS-80 CoCo ROMS you could also use my CoCo
emulator [emu09](https://github.com/mseminatore/emu09).

## Game tips

There are more than 80 rooms so drawing a map with graph paper is recommended! There are interesting items to find, puzzles to solve and mysteries to unravel as you explore your environment.

The commands are typically of the form: VERB or VERB NOUN. Here are some examples:

Command | Action
------- | ------
HELP | Show some example commands
EAST | Move East
NORTH | Move North
SOUTH | Move South
WEST | Move West
TAKE <item> | Pick up the named item
GET <item> | Same as take
DROP <item> | Drop the named item
INV | List the items you are carrying
READ <item> | Try to read the named item
OPEN DOOR | Try to open the door
UNLOCK DOOR | Try to unlock the door
LOOK | Describe the environment around you
SCORE | Report the current score
QUIT | Exit the game

> There are also synonyms and some undocumented commands. Look at the source code to find them.

Hint: There can be more than one item of the same type. When picking up an item, for example a BLEACH BOTTLE, be specific and type GET BLEACH BOTTLE.

## Dependencies

To build this project you need to have `as09` and `dsktools` projects built and installed. I am going to
reconfigure this project to include those dependencies as git submodules to make this simpler.

## Releases

Because building the executable is a little complicated, I've published a [release](https://github.com/mseminatore/adventure/releases) that includes a pre-built `ADV.DSK` file.

## Running in the browser (xroar-online)

You can run the downloaded release package, or built disk image, `ADV.DSK` using the xroar-online emulator hosted at https://colorcomputerarchive.com/xroar-online/.

Steps:

1. Open the emulator page in your browser: https://colorcomputerarchive.com/xroar-online/
2. Click the "Load..." button under the emulation display.
3. Navigate to and select the `ADV.DSK` file to add the disk image to the emulator.
4. In the emulator type `DIR` to view the contents of the virtual disk drive. You should see at least
two files `LOADER.BAS` and `ADV.BIN`.
5. At the flashing prompt type `RUN "LOADER"`.
6. Enjoy the game!

