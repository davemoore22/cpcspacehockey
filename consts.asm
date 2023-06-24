; Constants/Defines

; Firmware Calls
;
; http://www.cantrell.org.uk/david/tech/cpc/cpc-firmware/
KM_GET_JOYSTICK EQU #BB24				; Check the Joystick (INKEY)
KM_TEST_KEY EQU	#BB1E					; Check the Keyboard (INKEY)
MC_WAIT_FLYBACK EQU #BD19				; Wait for Frame Flyback (FRAME)
SCR_CLEAR EQU #BC14						; Clear the Screen (CLS)
SCR_RESET EQU #BB02						; Reset the Screen
SCR_SET_BORDER EQU #BC38				; Set the Border Colour (BORDER)
SCR_SET_INK EQU #BC32					; Set an Ink Colour (INK)
SCR_SET_MODE EQU #BC0E					; Set the Screen Mode (MODE)
TXT_SET_M_TABLE EQU #BBAB				; Set the Start of the UDG Table (SYMBOL AFTER)
TXT_SET_MATRIX EQU #BBA8				; Set the UDG (SYMbOL)
TXT_OUTPUT EQU #BB5A					; Print a Character (PRINT)
TXT_SET_CURSOR EQU #BB75				; Set the Cursor Position (LOCATE)
TXT_SET_PAPER EQU #BB96					; set the Paper Colour (PAPER)
TXT_SET_PEN EQU #BB90					; Set the Pen Colour (PEN)

; Keyboard Mappings
;
; https://lronaldo.github.io/cpctelera/files/keyboard/keyboard-h.html
P1_DOWN EQU 73							; Joystick
P1_FIRE EQU 76
P1_LEFT EQU 74
P1_RIGHT EQU 75
P1_UP EQU 72
P2_DOWN EQU 69							; Q, A, O, P, Space
P2_FIRE EQU 47
P2_LEFT EQU 34
P2_RIGHT EQU 27
P2_UP EQU 67
KEY_QUIT EQU 34							; Q

; Characters
CHR_BALL EQU #FF
CHR_GOALS EQU '='
CHR_BANNER EQU #FA
CHR_DOWN EQU #FC
CHR_LEFT EQU #FD
CHR_RIGHT EQU #FE
CHR_UP EQU #FB
CHR_SPACE EQU ' '

; UDGs
UDG_FIRST EQU #FA						; First UDG

; Game State Offsets
P1_OLD_Y EQU #00						; Player 1 info
P1_OLD_X EQU #01
P1_Y EQU #02
P1_X EQU #03
P1_CHAR EQU #04
P1_SCORE EQU #05
P2_OLD_Y EQU #06						; Player 2 info
P2_OLD_X EQU #07
P2_Y EQU #08
P2_X EQU #09
P2_CHAR EQU #0A
P2_SCORE EQU #0B
BALL_OLD_Y EQU #0C						; Ball info
BALL_OLD_X EQU #0D
BALL_Y EQU #0E
BALL_X EQU #0F

; Time
GAME_TIME_MSB EQU #10					; Initial time BCD MSB
GAME_TIME_DIGITS EQU 2					; Length of BCD storage for BCD functions

