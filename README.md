# Space Hockey

A fast-paced 2-player game for the Amstrad CPC. This is a port of the _Space Hockey_ Type-In by David Hay in [Amstrad Action Issue 42 (March 1989)](https://www.cpcwiki.eu/index.php/Amstrad_Action_March_1989_Type-Ins) from Locomotive Basic to Z80 Assembly Language.

Original Type in is in `HOCKEY.BAS` (with a couple of small bug-fixes). I ported it to ASM as a learning experience as I never could get my head around anything other than BASIC back in the 1980s, and Space Hockey was the first ever type-in from Amstrad Action that I typed in.

![new-title-screen](https://github.com/davemoore22/cpcspacehockey/assets/48893555/08691642-50e1-4a6e-b230-f6f4e44d7ea4)

![in-game](https://github.com/davemoore22/cpcspacehockey/assets/48893555/3df466ab-07fe-4954-83ae-56b370e229fc)

![gamr-over](https://github.com/davemoore22/cpcspacehockey/assets/48893555/7d077248-ed51-4e5e-b577-72d83acbf3fd)

Note that the Controls have changed compared to the original Type-In.

Player 1 (Red) - Joystick to move, Fire to return to Goal Line (or Cursor Keys/Z in an Emulator)
Player 2 (Yellow) - QAOP tro move, Spare to return to Goal Line

Q to quit on Title Screen/Game Over screen

Game is fully playable and almost identical to the original type-in although it runs faster than the BASIC version.

Compiled using the excellent [RASM](https://github.com/EdouardBERGE/rasm) assembler on Linux with

`./rasm/rasm_linux64 -eo ./main.asm`

To run it in an Emulator, such as [Caprice](https://github.com/ColinPitrat/caprice32/) that supports injecting directly use something like:

`../caprice32/cap32 -a "MEMORY &7fff" -i ./hockey.bin -o 0x8000`

By default RASM will produce a BIN file, but by changing a setting in `main.asm` a CDT or DSK file will be generated that will work with most emulators and real CPCs (just remember to do `MEMORY &7FFF` if loading from BASIC).

Standard Firmware Calls are used so should be compatible with all models of CPC.

Please note that the code will need a few adjustments to work with WINAPE's inbuilt compiler.

Change Log:

v1.0.1 (04/07/2023):

- Added Diagonal Ball Movement
- Fixed a bug with Player 2 not being able to move to the very top of the Playing Area
- Added Game Over Sound Effect

v1.0.0 (01/07/2023):

- Initial Release
