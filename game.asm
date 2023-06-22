; Handle main game loop
; ---------------------
main_game_loop:
	
	; Check for game over (i.e. main timer expired)
	ld de, time_left
	ld hl, time_game_over
	ld b, GAME_TIME_DIGITS
	call _bcd_compare
	ret z

	; Otherwise continue
	call update_game_screen
	call handle_input
	
	; Decrement the timer
	ld de, time_left
	ld hl, time_decrement	
	ld b, GAME_TIME_DIGITS
	call _bcd_subtract

	jp main_game_loop

; Display title screen
; --------------------
display_title_screen:

	; Initialise and clear the screen
	call SCR_RESET
	call SCR_CLEAR

	; Set screen mode
	ld a, #01
	call SCR_SET_MODE

	; Set border colour
	ld bc, #0B0B
	call SCR_SET_BORDER

	; Set pen and paper
	ld a, #01
	call TXT_SET_PEN
	ld a, #00
	call TXT_SET_PAPER

	; Display title text
	ld hl, #0802
	call TXT_SET_CURSOR
	ld hl, str_title
	call _print_string

	; Display credits
	ld a, #02
	call TXT_SET_PEN
	ld hl, #0304
	call TXT_SET_CURSOR
	ld hl, str_credits_1
	call _print_string
	ld hl, #0205
	call TXT_SET_CURSOR
	ld hl, str_credits_2
	call _print_string

	; Display ready message
	ld a, #01
	call TXT_SET_PEN
	ld hl, #0717
	call TXT_SET_CURSOR
	ld hl, str_start_game
	call _print_string

	ret

; Title screen keyboard loop
; --------------------------
wait_for_title_screen_keys:
wait_for_game_over_screen_keys:

	; Check for space or joystick fire
	ld a, INPUT_P1_FIRE
	call KM_TEST_KEY
	ret nz
	ld a, INPUT_P2_FIRE
	call KM_TEST_KEY
	ret nz

	; Loop around until either are pressed
	jp wait_for_title_screen_keys
	
; Setup UDCs
; ----------
setup_user_defined_characters:

	; Set the start of the UDCs
	ld de, UDG_FIRST
	ld hl, matrix_table
	call TXT_SET_M_TABLE

	; Load the UDCs
	ld a, CHR_BANNER
	ld hl, udg_banner
	call TXT_SET_MATRIX

	ld a, CHR_PLAYER_UP
	ld hl, udg_player_up
	call TXT_SET_MATRIX

	ld a, CHR_PLAYER_DOWN
	ld hl, udg_player_down
	call TXT_SET_MATRIX

	ld a, CHR_PLAYER_LEFT
	ld hl, udg_player_left
	call TXT_SET_MATRIX

	ld a, CHR_PLAYER_RIGHT
	ld hl, udg_player_right
	call TXT_SET_MATRIX

	ld a, CHR_BALL
	ld hl, udg_ball
	call TXT_SET_MATRIX
	
 	ret

; Clear and setup game state
; --------------------------
setup_game_state:

	; Get the area of memory for storing game data
	ld ix, time_left

	ld (ix), #00						; Initial game time left
	ld (ix + 1), GAME_TIME_MSB

	ld ix, game_state

	; Initial data for player 1
	ld (ix + OFFSET_P1_X), 5
	ld (ix + OFFSET_P1_Y), 16
	ld (ix + OFFSET_P1_OLD_X), 5
	ld (ix + OFFSET_P1_OLD_Y), 16
	ld (ix + OFFSET_P1_CHAR), CHR_PLAYER_RIGHT
	ld (ix + OFFSET_P1_SCORE), 0

	; Initial data for player 2
	ld (ix + OFFSET_P2_X), 35
	ld (ix + OFFSET_P2_Y), 5
	ld (ix + OFFSET_P2_OLD_X), 35
	ld (ix + OFFSET_P2_OLD_Y), 5
	ld (ix + OFFSET_P2_CHAR), CHR_PLAYER_LEFT
	ld (ix + OFFSET_P2_SCORE), 0

	; Initial ball position
	ld (ix + OFFSET_BALL_OLD_X), 20	
	ld (ix + OFFSET_BALL_OLD_Y), 11
	ld (ix + OFFSET_BALL_X), 20	
	ld (ix + OFFSET_BALL_Y), 11

	ret

; Draw game UI
; ------------
draw_game_screen:

	; Wait for frame flyback to avoid flicker and clear the screen
	call MC_WAIT_FLYBACK				
	call SCR_CLEAR

	; Set inks
	ld a, 0	
	ld b, 0
	ld c, 0
	call SCR_SET_INK

	; Draw goals
	ld a, #01
	call TXT_SET_PEN
	ld a, #00
	call TXT_SET_PAPER

	ld a, CHR_GOALS
	ld hl, #0105
	call TXT_SET_CURSOR
	ld a, CHR_GOALS
	call TXT_OUTPUT
	ld hl, #2805
	call TXT_SET_CURSOR
	ld a, CHR_GOALS
	call TXT_OUTPUT
	ld hl, #0111	
	call TXT_SET_CURSOR
	ld a, CHR_GOALS
	call TXT_OUTPUT
	ld hl, #2811	
	call TXT_SET_CURSOR
	ld a, CHR_GOALS
	call TXT_OUTPUT

	; Draw bottom HUD
	ld a, CHR_BANNER
	ld b, 40
	ld hl, #0117
	loop:
	push hl
	push bc
 	call TXT_SET_CURSOR
	ld a, CHR_BANNER
	call TXT_OUTPUT
	pop bc
	pop hl
	inc h
	djnz loop

	ld hl, #0818
	call TXT_SET_CURSOR
	ld hl, str_bottom_text
	call _print_string

	ld hl, #0419
	call TXT_SET_CURSOR
	ld hl, str_game_score_p1
	call _print_string

	ld hl, #1C19
	call TXT_SET_CURSOR
	ld hl, str_game_score_p2
	call _print_string

	; Draw initial time
	ld hl, #1219
	call TXT_SET_CURSOR
	ld de, time_left
	ld b, GAME_TIME_DIGITS
	call _bcd_show

	ret

; Game over screen
; ----------------
game_over_screen:

	; Clear the screen
	call SCR_CLEAR

	; Set pen and paper
	ld a, #01
	call TXT_SET_PEN
	ld a, #00
	call TXT_SET_PAPER

	; Display game over message
	ld hl, #0D02
	call TXT_SET_CURSOR
	ld hl, str_game_over
	call _print_string

	; Display scores
	ld a, #03
	call TXT_SET_PEN
	ld hl, #0F08	
	call TXT_SET_CURSOR
	ld hl, str_p1_name
	call _print_string

	ld a, #01
	call TXT_SET_PEN
	ld hl, #0F0A
	call TXT_SET_CURSOR
	ld hl, str_p2_name
	call _print_string

	; Display play again message
	ld a, #01
	call TXT_SET_PEN
	ld hl, #0517
	call TXT_SET_CURSOR
	ld hl, str_play_again
	call _print_string

	ret

; Update game screen
; ------------------
update_game_screen

	call MC_WAIT_FLYBACK

	; Draw timer
	ld a, #01
	call TXT_SET_PEN
	ld hl, #1219
	call TXT_SET_CURSOR
	ld de, time_left
	ld b, GAME_TIME_DIGITS
	call _bcd_show

	; Draw ball (cyan)
	ld a, #02
	call TXT_SET_PEN
	ld ix, game_state
	ld hl, (ix + OFFSET_BALL_Y)
	call TXT_SET_CURSOR
	ld a, CHR_BALL
	call TXT_OUTPUT

	; Draw player 1 (red)
	ld a, #03							
	call TXT_SET_PEN
	ld ix, game_state
	ld hl, (ix + OFFSET_P1_Y)
	call TXT_SET_CURSOR
	ld a, (ix + OFFSET_P1_CHAR)
	call TXT_OUTPUT

	; Draw player 2 (yellow)
	ld a, #01							
	call TXT_SET_PEN
	ld ix, game_state
	ld hl, (ix + OFFSET_P2_Y)
	call TXT_SET_CURSOR
	ld a, (ix + OFFSET_P2_CHAR)
	call TXT_OUTPUT

	ret

; Check for any inputs
; --------------------
handle_input:
handle_input_p1:

	; Check for player 1 controls
	ld a, INPUT_P1_UP
	call KM_TEST_KEY
	jp nz, _p1_move_up
	ld a, INPUT_P1_DOWN
	call KM_TEST_KEY
	jp nz, _p1_move_down
	ld a, INPUT_P1_LEFT
	call KM_TEST_KEY
	jp nz, _p1_move_left
	ld a, INPUT_P1_RIGHT
	call KM_TEST_KEY
	jp nz, _p1_move_right
	ld a, INPUT_P1_FIRE
	call KM_TEST_KEY
	jp nz, _p1_fire

return_from_movement_p1:
handle_input_p2:

	; Check for player 2 controls
	ld a, INPUT_P2_UP
	call KM_TEST_KEY
	jp nz, _p2_move_up
	ld a, INPUT_P2_DOWN
	call KM_TEST_KEY
	jp nz, _p2_move_down
	ld a, INPUT_P2_LEFT
	call KM_TEST_KEY
	jp nz, _p2_move_left
	ld a, INPUT_P2_RIGHT
	call KM_TEST_KEY
	jp nz, _p2_move_right
	ld a, INPUT_P2_FIRE
	call KM_TEST_KEY
	jp nz, _p2_fire

return_from_movement_p2:

	ret

; Player 1 movement
; -----------------
_p1_move_up:

	; Check for edge of playing area
	ld ix, game_state
	ld a, (game_state + OFFSET_P1_Y);
	cp a, 2
	jp z, return_from_movement_p1

	; If we can move, store the current location then move
	ld ix, game_state
	ld a, (ix + OFFSET_P1_Y)
	ld (ix + OFFSET_P1_OLD_Y), a
	dec a
	ld (ix + OFFSET_P1_Y), a
	ld a, CHR_PLAYER_UP
	ld (ix + OFFSET_P1_CHAR), a
	jp return_from_movement_p1

_p1_move_down:

	; Check for edge of playing area
	ld ix, game_state
	ld a, (ix + OFFSET_P1_Y);
	cp a, 22
	jp z, return_from_movement_p1

	; If we can move, store the current location then move
	ld ix, game_state
	ld a, (ix + OFFSET_P1_Y)
	ld (ix + OFFSET_P1_OLD_Y), a
	inc a
	ld (ix + OFFSET_P1_Y), a
	ld a, CHR_PLAYER_DOWN
	ld (ix + OFFSET_P1_CHAR), a
	jp return_from_movement_p1 

_p1_move_left:

	; Check for edge of playing area
	ld ix, game_state
	ld a, (ix + OFFSET_P1_X);
	cp a, 2
	jp z, return_from_movement_p1

	; If we can move, store the current location then move
	ld ix, game_state
	ld a, (ix + OFFSET_P1_X)
	ld (ix + OFFSET_P1_OLD_X), a
	dec a
	ld (ix + OFFSET_P1_X), a
	ld a, CHR_PLAYER_LEFT
	ld (ix + OFFSET_P1_CHAR), a
	jp return_from_movement_p1

_p1_move_right:

	; Check for edge of playing area
	ld ix, game_state
	ld a, (ix + OFFSET_P1_X);
	cp a, 39
	jp z, return_from_movement_p1

	; If we can move, store the current location then move
	ld ix, game_state
	ld a, (ix + OFFSET_P1_X)
	ld (ix + OFFSET_P1_OLD_X), a
	inc a
	ld (ix + OFFSET_P1_X), a
	ld a, CHR_PLAYER_RIGHT
	ld (ix + OFFSET_P1_CHAR), a
	jp return_from_movement_p1

_p1_fire:

	; Return to goal
	ld ix, game_state
	ld a, (ix + OFFSET_P1_X)
	ld (ix + OFFSET_P1_OLD_X), a
	ld a, 2
	ld (ix + OFFSET_P1_X), a
	ld a, CHR_PLAYER_RIGHT
	ld (ix + OFFSET_P1_CHAR), a
	jp return_from_movement_p1


; Player 2 movement
; -----------------
_p2_move_up:

	; Check for edge of playing area
	ld ix, game_state
	ld a, (ix + OFFSET_P2_Y)
	cp a, 2
	jp z, return_from_movement_p2

	; If we can move, store the current location then move
	ld ix, game_state
	ld a, (ix + OFFSET_P2_Y)
	ld (ix + OFFSET_P2_OLD_Y), a
	dec a
	ld (ix + OFFSET_P2_Y), a
	ld a, CHR_PLAYER_UP
	ld (ix + OFFSET_P2_CHAR), a
	jp return_from_movement_p2

_p2_move_down:

	; Check for edge of playing area
	ld ix, game_state
	ld a, (ix + OFFSET_P2_Y);
	cp a, 22
	jp z, return_from_movement_p2

	; If we can move, store the current location then move
	ld ix, game_state
	ld a, (ix + OFFSET_P2_Y)
	ld (ix + OFFSET_P2_OLD_Y), a
	inc a
	ld (ix + OFFSET_P2_Y), a
	ld a, CHR_PLAYER_DOWN
	ld (ix + OFFSET_P2_CHAR), a
	jp return_from_movement_p2 

_p2_move_left:

	; Check for edge of playing area
	ld ix, game_state
	ld a, (ix + OFFSET_P2_X);
	cp a, 2
	jp z, return_from_movement_p2

	; If we can move, store the current location then move
	ld ix, game_state
	ld a, (ix + OFFSET_P2_X)
	ld (ix + OFFSET_P2_OLD_X), a
	dec a
	ld (ix + OFFSET_P2_X), a
	ld a, CHR_PLAYER_LEFT
	ld (ix + OFFSET_P2_CHAR), a
	jp return_from_movement_p2

_p2_move_right:

	; Check for edge of playing area
	ld ix, game_state
	ld a, (ix + OFFSET_P2_X);
	cp a, 39
	jp z, return_from_movement_p2

	; If we can move, store the current location then move
	ld ix, game_state
	ld a, (ix + OFFSET_P2_X)
	ld (ix + OFFSET_P2_OLD_X), a
	inc a
	ld (ix + OFFSET_P2_X), a
	ld a, CHR_PLAYER_RIGHT
	ld (ix + OFFSET_P2_CHAR), a
	jp return_from_movement_p2

_p2_fire:

	; Return to goal
	ld ix, game_state
	ld a, (ix + OFFSET_P2_X)
	ld (ix + OFFSET_P2_OLD_X), a
	ld a, 39
	ld (ix + OFFSET_P2_X), a
	ld a, CHR_PLAYER_LEFT
	ld (ix + OFFSET_P2_CHAR), a
	jp return_from_movement_p2


; Print a string
; --------------
; In: HL = address of string to print (terminated by #00)
_print_string:

	ld a, (hl)
	cp #00
	ret z
	inc hl
	call TXT_OUTPUT
	jr _print_string


