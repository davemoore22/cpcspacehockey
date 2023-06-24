; Space-Hockey
; Original (c) David Hay 1988 (AA42)
; Z80 Rewrite (c) Dave Moore 2023
;
; ../rasm/rasm_linux64 -eo ./main.asm
; ../caprice32/cap32 -a "MEMORY &7fff" -i ./hockey.bin -o 0x8000

ORG #8000
BEGIN_CODE

setup:

	call setup_user_defined_characters	; Title screen and setup

start_game:

	call display_title_screen
	call wait_for_keys

	ld a, (quit_flag)					; Exit if Q key is pressed
	cp #FF
	ret z

restart_game:

	call initalise_game_state
	call draw_game_screen				; Main game loop
	call main_game_loop

	call game_over_screen				; Game over
	call wait_for_keys

	ld a, (quit_flag)					; Exit if Q key is pressed
	cp #FF
	ret z

	jp restart_game

ALIGN #100

INCLUDE 'game.asm'
INCLUDE 'consts.asm'
INCLUDE 'strings.asm'
INCLUDE 'funcs.asm'

ALIGN #100

matrix_table:							; Space for UDCs

	DEFB 0, 0, 0, 0, 0, 0, 0, 0
	DEFB 0, 0, 0, 0, 0, 0, 0, 0
	DEFB 0, 0, 0, 0, 0, 0, 0, 0
	DEFB 0, 0, 0, 0, 0, 0, 0, 0
	DEFB 0, 0, 0, 0, 0, 0, 0, 0
	DEFB 0, 0, 0, 0, 0, 0, 0, 0


game_state:								; Space for game state

	DEFB 0, 0, 0, 0, 0, 0				; Player 1 old_x, old_y, x, y, character, score
	DEFB 0, 0, 0, 0, 0, 0				; Player 2 old_x, old_y, x, y, character, score
	DEFB 0, 0, 0, 0						; Ball old_x, old_y, x, y

quit_flag:

	DEFB #00							; Set if we want to quit

time_left:								; Space for timer

	DEFB #00, #00						; Time left (Packed BCD - 4 Digits)

time_decrement:

	DEFB #01, #00						; Timer Decrement

time_game_over:

	DEFB #00, #00						; Game Over

END_CODE

; Save to DSK file
SAVE 'hockey.bin', BEGIN_CODE, END_CODE - BEGIN_CODE
;SAVE 'hockey.bin', BEGIN_CODE, END_CODE - BEGIN_CODE, DSK, 'hockey.dsk'
;SAVE 'hockey.bin', BEGIN_CODE, END_CODE - BEGIN_CODE, TAPE, 'hockey.cdt'

