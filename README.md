# cpcspacehockey
Port of the Space Hockey TypeIn by David Hay in Amstrad Action Issue 42 (May 1988) from  Locomotive Basic to Z80 Assembly Language

Original Type in is in HOCKEY.BAS

Comparison between Original and Rewrite:

![title-screen](https://github.com/davemoore22/cpcspacehockey/assets/48893555/546f00a9-fe1c-40c4-88e3-9972b9da9ace)

![new-title-screen](https://github.com/davemoore22/cpcspacehockey/assets/48893555/648ecc86-79f4-40ca-a562-cdf0046c33f5)

![in-game](https://github.com/davemoore22/cpcspacehockey/assets/48893555/8d8301c9-782f-45cd-a485-d94a22c2f9e2)

![new-in-game](https://github.com/davemoore22/cpcspacehockey/assets/48893555/7f551b94-57e4-4d9f-baf7-749b87a1d0a1)

Conbtrols have changed.

Player 1 (Red) - Joystick to move, Fire to return to Goal Line (or Cursor Keys/Z in an Emulator)
Player 2 (Yellow) - QAOP tro move, Spare to return to Goal Line

Q to quit on Title screen/Game Over screen


Compiled using rasm with

./rasm/rasm_linux64 -eo ./main.asm

And injected into Caprice32 and ran with

../caprice32/cap32 -a "MEMORY &7fff" -i ./hockey.bin -o 0x8000

Code will need a few adjustments to work with WINAPE's inbuilt compiler


