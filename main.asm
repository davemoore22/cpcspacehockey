; ******************************************************************************
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
; ******************************************************************************

;###############################################################################
; Space-Hockey
; Original (c) David Hay 1988 (AA42)
; Z80 Rewrite (c) Dave Moore 2023
;
; Example compilation and running with rasm and caprice32 under Linux:
;
; ../rasm/rasm_linux64 -eo ./main.asm
; ../caprice32/cap32 -a "MEMORY &7fff" -i ./hockey.bin -o 0x8000
;###############################################################################

ORG #8000
BEGIN_CODE

setup:
	call	setup_udcs		; Title screen and setup
start_game:
	call	show_title_screen
	call 	wait_for_keys

	ld 	a, (quit_flag)		; Exit if Q key is pressed
	cp 	#FF
	ret 	z

restart_game:
	call 	initalise_game_state
	call 	draw_game_screen	; Main game loop
	call 	main_game_loop

	call 	game_over_screen	; Game over
	call 	wait_for_keys

	ld a, 	(quit_flag)		; Exit if Q key is pressed
	cp 	#FF
	ret 	z

	jp 	restart_game

ALIGN #100

; Include all the other game code/data
INCLUDE 'game.asm'
INCLUDE 'consts.asm'
INCLUDE 'strings.asm'
INCLUDE 'funcs.asm'

ALIGN #100

INCLUDE 'data.asm'

END_CODE

; Save to DSK file
SAVE 'hockey.bin', BEGIN_CODE, END_CODE - BEGIN_CODE
;SAVE 'hockey.bin', BEGIN_CODE, END_CODE - BEGIN_CODE, DSK, 'hockey.dsk'
;SAVE 'hockey.bin', BEGIN_CODE, END_CODE - BEGIN_CODE, TAPE, 'hockey.cdt'

