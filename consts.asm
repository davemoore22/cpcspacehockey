;*******************************************************************************
;
; Copyright (C) 2023 Dave Moore
;
; This file is part of Space-Hockey.
;
; Space-Hockey is free software: you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation, either version 2 of the License, or (at your option) any later
; version.
;
; Space-Hockey is distributed in the hope that it will be useful, but WITHOUT 
; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
; details.
;
; You should have received a copy of the GNU General Public License along with
; Space-Hockey.  If not, see <http://www.gnu.org/licenses/>.
;
; If you modify this program, or any covered work, by linking or combining it
; with the libraries referred to in README (or a modified version of said
; libraries), containing parts covered by the terms of said libraries, the
; licensors of this program grant you additional permission to convey the 
; resulting work.
;
;*******************************************************************************

;###############################################################################
;
; Firmware Calls
;
; http://www.cantrell.org.uk/david/tech/cpc/cpc-firmware/
;
;###############################################################################

KM_GET_JOYSTICK 	EQU 	#BB24	; Check the Joystick (INKEY)
KM_TEST_KEY		EQU 	#BB1E	; Check the Keyboard (INKEY)
MC_WAIT_FLYBACK 	EQU 	#BD19	; Wait for Frame Flyback (FRAME)
SCR_CLEAR		EQU 	#BC14	; Clear the Screen (CLS)
SCR_RESET		EQU 	#BB02	; Reset the Screen
SCR_SET_BORDER		EQU 	#BC38	; Set the Border Colour (BORDER)
SCR_SET_INK		EQU 	#BC32	; Set an Ink Colour (INK)
SCR_SET_MODE		EQU 	#BC0E	; Set the Screen Mode (MODE)
SOUND_QUEUE		EQU	#BCAA	; Add a Sound to the Queue (SOUND)
TXT_CLEAR_WINDOW	EQU	#BB6C	; Clear the current Window
TXT_OUTPUT		EQU 	#BB5A	; Print a Character (PRINT)
TXT_SET_CURSOR		EQU 	#BB75	; Set the Cursor Position (LOCATE)
TXT_SET_M_TABLE 	EQU 	#BBAB	; Start of the UDG Table (SYMBOL AFTER)
TXT_SET_MATRIX		EQU 	#BBA8	; Set the UDG (SYMBOL)
TXT_SET_PAPER		EQU 	#BB96	; Set the Paper Colour (PAPER)
TXT_SET_PEN		EQU 	#BB90	; Set the Pen Colour (PEN)
TXT_STR_SELECT		EQU	#BBB4	; Choose the current Window
TXT_WIN_ENABLE		EQU	#BB66	; Set the current Window (WINDOW)

;###############################################################################
;
; Keyboard Mappings
;
; https://lronaldo.github.io/cpctelera/files/keyboard/keyboard-h.html
;
;###############################################################################

P1_DOWN 		EQU	73	; Joystick
P1_FIRE			EQU	76
P1_LEFT			EQU	74
P1_RIGHT		EQU	75
P1_UP			EQU	72
P2_DOWN			EQU	69	; Q/A/O/P/Space
P2_FIRE			EQU	47
P2_LEFT			EQU	34
P2_RIGHT		EQU	27
P2_UP			EQU	67
KEY_QUIT		EQU	34	; Q
RESET_KEY		EQU	64	; 1

;###############################################################################
;
; UDCs
;
;###############################################################################

UDC_FIRST		EQU	250	; First UDC

CHR_BANNER		EQU	250
CHR_UP			EQU	251
CHR_DOWN		EQU	252
CHR_LEFT		EQU	253
CHR_RIGHT		EQU	254
CHR_BALL		EQU	255

CHR_GOALS		EQU	'='
CHR_SPACE		EQU	' '

;###############################################################################
;
; Game State Offsets
;
;###############################################################################

P1_OLD_Y		EQU	#00	; P1 info
P1_OLD_X		EQU	#01
P1_Y			EQU	#02
P1_X			EQU	#03
P1_CHAR			EQU	#04
P1_SCORE		EQU	#05

P2_OLD_Y		EQU	#06	; P2 info
P2_OLD_X		EQU	#07
P2_Y			EQU	#08
P2_X			EQU	#09
P2_CHAR			EQU	#0A
P2_SCORE		EQU	#0B

BALL_OLD_Y		EQU	#0C	; Ball info
BALL_OLD_X		EQU	#0D
BALL_Y			EQU	#0E
BALL_X			EQU	#0F

TIME_MSB		EQU	#10	; Initial time BCD MSB
TIME_DIGITS		EQU	2	; Length of BCD number for BCD functions
