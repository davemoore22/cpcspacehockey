; Handle main game loop
; ---------------------
main_game_loop:
	
	ld de, time_left					; Check for game over (i.e. main timer expired)
	ld hl, time_game_over
	ld b, GAME_TIME_DIGITS
	call _bcd_compare
	ret z

	call update_game_screen				; Otherwise continue
	call handle_input
	
	ld de, time_left					; Decrement the timer
	ld hl, time_decrement	
	ld b, GAME_TIME_DIGITS
	call _bcd_subtract

	jp main_game_loop

; Display title screen
; --------------------
display_title_screen:

	call SCR_RESET						; Initialise and clear the screen
	call SCR_CLEAR

	ld a, 1								; Set screen mode
	call SCR_SET_MODE

	ld bc, #0B0B						; Set border colour
	call SCR_SET_BORDER

	ld a, 1								; Set pen and paper
	call TXT_SET_PEN
	ld a, 0
	call TXT_SET_PAPER

	
	ld hl, #0802						; Display title text
	call TXT_SET_CURSOR
	ld hl, str_title
	call _print_string

	ld a, 2								; Display credits
	call TXT_SET_PEN
	ld hl, #0304
	call TXT_SET_CURSOR
	ld hl, str_credits_1
	call _print_string
	ld hl, #0205
	call TXT_SET_CURSOR
	ld hl, str_credits_2
	call _print_string

	ld a, 1								; Display ready message
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

	ld a, INPUT_P1_FIRE					; Check for p1/p2 fire
	call KM_TEST_KEY
	ret nz
	ld a, INPUT_P2_FIRE
	call KM_TEST_KEY
	ret nz

	jp wait_for_title_screen_keys		; Loop around until either are pressed
	
; Setup UDCs
; ----------
setup_user_defined_characters:

	ld de, UDG_FIRST					; Set the start of the UDCs
	ld hl, matrix_table
	call TXT_SET_M_TABLE

	ld a, CHR_BANNER					; Load the UDCs starting from UDG_FIRST
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
initalise_game_state:

	ld ix, time_left					; Store the initial timer value
	ld (ix), 0							
	ld (ix + 1), GAME_TIME_MSB

	ld ix, game_state					; Initial data for player 1
	ld (ix + OFFSET_P1_Y), 16
	ld (ix + OFFSET_P1_X), 5			
	ld (ix + OFFSET_P1_OLD_Y), 16
	ld (ix + OFFSET_P1_OLD_X), 5
	ld (ix + OFFSET_P1_CHAR), CHR_PLAYER_RIGHT
	ld (ix + OFFSET_P1_SCORE), 0

	ld (ix + OFFSET_P2_Y), 5			; Initial data for player 2
	ld (ix + OFFSET_P2_X), 35
	ld (ix + OFFSET_P2_OLD_Y), 5
	ld (ix + OFFSET_P2_OLD_X), 35
	ld (ix + OFFSET_P2_CHAR), CHR_PLAYER_LEFT
	ld (ix + OFFSET_P2_SCORE), 0

	ld (ix + OFFSET_BALL_OLD_Y), 11		; Initial ball position
	ld (ix + OFFSET_BALL_OLD_X), 20		
	ld (ix + OFFSET_BALL_Y), 11
	ld (ix + OFFSET_BALL_X), 20	

	ret

; Draw game UI
; ------------
draw_game_screen:

	
	call MC_WAIT_FLYBACK				; Wait for frame flyback to avoid flicker
	call SCR_CLEAR

	ld a, 0								; Set inks
	ld b, 0
	ld c, 0
	call SCR_SET_INK
	ld a, 1								
	call TXT_SET_PEN
	ld a, 0
	call TXT_SET_PAPER

	ld a, CHR_GOALS						; Draw goals
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

	ld a, CHR_BANNER					; Draw bottom HUD
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

	call SCR_CLEAR						; Clear the screen

	ld a, 1								; Set pen and paper
	call TXT_SET_PEN
	ld a, 0
	call TXT_SET_PAPER

	ld hl, #0D02						; Display game over message
	call TXT_SET_CURSOR
	ld hl, str_game_over
	call _print_string

	ld a, 3								; Display scores
	call TXT_SET_PEN
	ld hl, #0F08	
	call TXT_SET_CURSOR
	ld hl, str_p1_name
	call _print_string

	ld a, 1
	call TXT_SET_PEN
	ld hl, #0F0A
	call TXT_SET_CURSOR
	ld hl, str_p2_name
	call _print_string

	ld a, 1								; Display play again message
	call TXT_SET_PEN
	ld hl, #0517
	call TXT_SET_CURSOR
	ld hl, str_play_again
	call _print_string

	ret

; Update game screen
; ------------------
update_game_screen

	call MC_WAIT_FLYBACK				; Wait for frame flyback to avoid flicker

	ld a, 1								; Draw timer
	call TXT_SET_PEN
	ld hl, #1219
	call TXT_SET_CURSOR
	ld de, time_left
	ld b, GAME_TIME_DIGITS
	call _bcd_show

	ld a, 2								; Draw ball
	call TXT_SET_PEN
	ld ix, game_state
	ld hl, (ix + OFFSET_BALL_Y)
	call TXT_SET_CURSOR
	ld a, CHR_BALL
	call TXT_OUTPUT

	ld a, 3								; Erase player 1
	call TXT_SET_PEN
	ld ix, game_state
	ld hl, (ix + OFFSET_P1_OLD_Y)
	call TXT_SET_CURSOR
	ld a, CHR_SPACE
	call TXT_OUTPUT

	ld a, 3								; Draw player 1					
	call TXT_SET_PEN
	ld ix, game_state
	ld hl, (ix + OFFSET_P1_Y)
	call TXT_SET_CURSOR
	ld a, (ix + OFFSET_P1_CHAR)
	call TXT_OUTPUT

	ld a, #03							; Erase player 2
	call TXT_SET_PEN
	ld ix, game_state
	ld hl, (ix + OFFSET_P2_OLD_Y)
	call TXT_SET_CURSOR
	ld a, CHR_SPACE
	call TXT_OUTPUT

	ld a, #01							; Draw player 2
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
_handle_input_p1:

	ld a, INPUT_P1_UP					; Check for player 1 controls
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

_return_p1:
_handle_input_p2:

	ld a, INPUT_P2_UP					; Check for player 2 controls
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

_return_p2:

	ret

; Player 1 movement
; -----------------
_p1_move_up:

	ld ix, game_state					; Check for edge of playing area
	ld a, (game_state + OFFSET_P1_Y);
	cp a, 2
	jp z, _return_p1					; If we are at the edge don't do anything

	ld ix, game_state					; Store the current location
	ld a, (ix + OFFSET_P1_Y)
	ld (ix + OFFSET_P1_OLD_Y), a
	
	dec a								; Move
	ld (ix + OFFSET_P1_Y), a
	ld a, CHR_PLAYER_UP
	ld (ix + OFFSET_P1_CHAR), a
	jp _return_p1

_p1_move_down:

	ld ix, game_state					; Check for edge of playing area
	ld a, (ix + OFFSET_P1_Y);
	cp a, 22
	jp z, _return_p1					; If we are at the edge don't do anything

	ld ix, game_state					; Store the current location
	ld a, (ix + OFFSET_P1_Y)
	ld (ix + OFFSET_P1_OLD_Y), a
	
	inc a								; Move
	ld (ix + OFFSET_P1_Y), a
	ld a, CHR_PLAYER_DOWN
	ld (ix + OFFSET_P1_CHAR), a
	jp _return_p1 

_p1_move_left:

	ld ix, game_state					; Check for edge of playing area
	ld a, (ix + OFFSET_P1_X);
	cp a, 2
	jp z, _return_p1					; If we are at the edge don't do anything

	ld ix, game_state
	ld a, (ix + OFFSET_P1_X)
	ld (ix + OFFSET_P1_OLD_X), a		; Store the current location
	
	dec a								; Move
	ld (ix + OFFSET_P1_X), a
	ld a, CHR_PLAYER_LEFT
	ld (ix + OFFSET_P1_CHAR), a
	jp _return_p1

_p1_move_right:

	ld ix, game_state					; Check for edge of playing area
	ld a, (ix + OFFSET_P1_X);
	cp a, 39
	jp z, _return_p1					; If we are at the edge don't do anything

	ld ix, game_state
	ld a, (ix + OFFSET_P1_X)
	ld (ix + OFFSET_P1_OLD_X), a		; Store the current location
	
	inc a								; Move
	ld (ix + OFFSET_P1_X), a
	ld a, CHR_PLAYER_RIGHT
	ld (ix + OFFSET_P1_CHAR), a
	jp _return_p1

; Return to goal
_p1_fire:

	ld ix, game_state					; Store the current location
	ld a, (ix + OFFSET_P1_X)
	ld (ix + OFFSET_P1_OLD_X), a
	
	ld a, 2								; Move
	ld (ix + OFFSET_P1_X), a
	ld a, CHR_PLAYER_RIGHT
	ld (ix + OFFSET_P1_CHAR), a
	jp _return_p1


; Player 2 movement
; -----------------
_p2_move_up:

	ld ix, game_state					; Check for edge of playing area
	ld a, (ix + OFFSET_P2_Y)
	cp a, 2
	jp z, _return_p2

	ld ix, game_state					; If we are at the edge don't do anything
	ld a, (ix + OFFSET_P2_Y)
	ld (ix + OFFSET_P2_OLD_Y), a		; Store the current location
	
	dec a								; Move
	ld (ix + OFFSET_P2_Y), a
	ld a, CHR_PLAYER_UP
	ld (ix + OFFSET_P2_CHAR), a
	jp _return_p2

_p2_move_down:

	ld ix, game_state					; Check for edge of playing area
	ld a, (ix + OFFSET_P2_Y);
	cp a, 22
	jp z, _return_p2

	ld ix, game_state					; If we are at the edge don't do anything
	ld a, (ix + OFFSET_P2_Y)
	ld (ix + OFFSET_P2_OLD_Y), a		; Store the current location
	
	inc a								; Move
	ld (ix + OFFSET_P2_Y), a
	ld a, CHR_PLAYER_DOWN
	ld (ix + OFFSET_P2_CHAR), a
	jp _return_p2 

_p2_move_left:

	; Check for edge of playing area
	ld ix, game_state					; Check for edge of playing area
	ld a, (ix + OFFSET_P2_X);
	cp a, 2
	jp z, _return_p2

	ld ix, game_state					; If we are at the edge don't do anything
	ld a, (ix + OFFSET_P2_X)
	ld (ix + OFFSET_P2_OLD_X), a		; Store the current location
	
	dec a								; Move
	ld (ix + OFFSET_P2_X), a
	ld a, CHR_PLAYER_LEFT
	ld (ix + OFFSET_P2_CHAR), a
	jp _return_p2

_p2_move_right:

	; Check for edge of playing area
	ld ix, game_state					; Check for edge of playing area
	ld a, (ix + OFFSET_P2_X);
	cp a, 39
	jp z, _return_p2

	ld ix, game_state					; If we are at the edge don't do anything
	ld a, (ix + OFFSET_P2_X)
	ld (ix + OFFSET_P2_OLD_X), a		; Store the current location
	

	inc a								; Move
	ld (ix + OFFSET_P2_X), a
	ld a, CHR_PLAYER_RIGHT
	ld (ix + OFFSET_P2_CHAR), a
	jp _return_p2

_p2_fire:

	; Return to goal
	ld ix, game_state					; Store the current location
	ld a, (ix + OFFSET_P2_X)
	ld (ix + OFFSET_P2_OLD_X), a
	
	ld a, 39							; Move
	ld (ix + OFFSET_P2_X), a
	ld a, CHR_PLAYER_LEFT
	ld (ix + OFFSET_P2_CHAR), a
	jp _return_p2


; Print a string
; --------------
_print_string:

	ld a, (hl)							; HL = address of string to print (terminated by #00)
	cp #00
	ret z
	inc hl
	call TXT_OUTPUT
	jr _print_string


