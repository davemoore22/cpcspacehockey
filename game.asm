; Handle main game loop
; ---------------------
main_game_loop:

	ld de, time_left					; Check for game over (i.e. main timer expired)
	ld hl, time_game_over
	ld b, GAME_TIME_DIGITS
	call _bcd_compare
	ret z

	call refresh_game_screen			; Otherwise continue
	call handle_input
	call handle_ball_movement
	call check_for_goal_scored

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
wait_for_keys:

	ld a, P1_FIRE						; Check for p1/p2 fire
	call KM_TEST_KEY
	jr nz, continue
	ld a, P2_FIRE
	call KM_TEST_KEY
	jr nz, continue

	ld a, KEY_QUIT						; Check for Q to quit
	call KM_TEST_KEY
	jr nz, quit_game

	jp wait_for_keys					; Loop around

quit_game:

	ld a, #FF							; If we want to quit, return from this with quit flag set
	ld (quit_flag), a
	ret

continue:

	ld a, 0
	ld (quit_flag), a
	ret

; Setup UDCs
; ----------
setup_user_defined_characters:

	ld de, UDG_FIRST					; Set the start of the UDCs
	ld hl, matrix_table
	call TXT_SET_M_TABLE

	ld a, CHR_BANNER					; Load the UDCs starting from UDG_FIRST
	ld hl, udg_banner
	call TXT_SET_MATRIX

	ld a, CHR_UP
	ld hl, udg_player_up
	call TXT_SET_MATRIX

	ld a, CHR_DOWN
	ld hl, udg_player_down
	call TXT_SET_MATRIX

	ld a, CHR_LEFT
	ld hl, udg_player_left
	call TXT_SET_MATRIX

	ld a, CHR_RIGHT
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

reset_player_and_ball_positions:

	ld ix, game_state					; Initial data for player 1
	ld (ix + P1_Y), 16
	ld (ix + P1_X), 5
	ld (ix + P1_OLD_Y), 16
	ld (ix + P1_OLD_X), 5
	ld (ix + P1_CHAR), CHR_RIGHT
	ld (ix + P1_SCORE), 0

	ld (ix + P2_Y), 5					; Initial data for player 2
	ld (ix + P2_X), 35
	ld (ix + P2_OLD_Y), 5
	ld (ix + P2_OLD_X), 35
	ld (ix + P2_CHAR), CHR_LEFT
	ld (ix + P2_SCORE), 0

	ld (ix + BALL_OLD_Y), 11			; Initial ball position
	ld (ix + BALL_OLD_X), 20
	ld (ix + BALL_Y), 11
	ld (ix + BALL_X), 20

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
refresh_game_screen

	call MC_WAIT_FLYBACK				; Wait for frame flyback to avoid flicker

	ld a, 1								; Draw timer
	call TXT_SET_PEN
	ld hl, #1219
	call TXT_SET_CURSOR
	ld de, time_left
	ld b, GAME_TIME_DIGITS
	call _bcd_show

	ld a, 3								; Erase ball
	call TXT_SET_PEN
	ld hl, (game_state + BALL_OLD_Y)
	call TXT_SET_CURSOR
	ld a, CHR_SPACE
	call TXT_OUTPUT

	ld a, 2								; Draw ball
	call TXT_SET_PEN
	ld ix, game_state
	ld hl, (game_state + BALL_Y)
	call TXT_SET_CURSOR
	ld a, CHR_BALL
	call TXT_OUTPUT

	ld a, 3								; Erase player 1
	call TXT_SET_PEN
	ld hl, (game_state + P1_OLD_Y)
	call TXT_SET_CURSOR
	ld a, CHR_SPACE
	call TXT_OUTPUT

	ld a, 3								; Draw player 1
	call TXT_SET_PEN
	ld hl, (game_state + P1_Y)
	call TXT_SET_CURSOR
	ld a, (game_state + P1_CHAR)
	call TXT_OUTPUT

	ld a, 3								; Erase player 2
	call TXT_SET_PEN
	ld hl, (game_state + P2_OLD_Y)
	call TXT_SET_CURSOR
	ld a, CHR_SPACE
	call TXT_OUTPUT

	ld a, 1								; Draw player 2
	call TXT_SET_PEN
	ld hl, (game_state + P2_Y)
	call TXT_SET_CURSOR
	ld a, (game_state + P2_CHAR)
	call TXT_OUTPUT

	ret


; Check for collision detection between the ball and the players
; --------------------------------------------------------------
;
; if player is adjacent to the ball then move it away in the opposite direction
handle_ball_movement:

	or a
	ld a, (game_state + BALL_X)			; Work out the offset from first player to the ball
	ld b, a
	ld a, (game_state + P1_X)
	call _find_abs_diff_numbers
	ld c, a
	or a
	ld a, (game_state + BALL_Y)
	ld b, a
	ld a, (game_state + P1_Y)
	call _find_abs_diff_numbers
	ld b, a								; Store in B and C for now

	or a
	ld a, (game_state + BALL_X)			; Work out the offset from second player to the ball
	ld b, a
	ld a, (game_state + P2_X)
	call _find_abs_diff_numbers
	ld e, a
	or a
	ld a, (game_state + BALL_Y)			
	ld b, a
	ld a, (game_state + P2_Y)
	call _find_abs_diff_numbers
	ld d, a								; Store in D and E for now

	or a
	ld a, d								; Quickly exit if players are not adjacent
	cp 2
	ret z
	ret nc

	or a
	ld a, e								
	cp 2
	ret z
	ret nc

	or a
	ld a, b								
	cp 2
	ret z
	ret nc

	or a
	ld a, c								
	cp 2
	ret z
	ret nc

	ld a, 7
	call TXT_OUTPUT


	ret

; Check for a goal being scored
check_for_goal_scored:


	ret


; Check for any inputs
; --------------------
handle_input:

	ld a, P1_UP							; Check for player 1 controls
	call KM_TEST_KEY
	jp nz, p1_move_up

	ld a, P1_DOWN
	call KM_TEST_KEY
	jp nz, p1_move_down

	ld a, P1_LEFT
	call KM_TEST_KEY
	jp nz, p1_move_left

	ld a, P1_RIGHT
	call KM_TEST_KEY
	jp nz, p1_move_right

	ld a, P1_FIRE
	call KM_TEST_KEY
	jp nz, p1_return_goal

return_p1:

	ld a, P2_UP							; Check for player 2 controls
	call KM_TEST_KEY
	jp nz, p2_move_up

	ld a, P2_DOWN
	call KM_TEST_KEY
	jp nz, p2_move_down

	ld a, P2_LEFT
	call KM_TEST_KEY
	jp nz, p2_move_left

	ld a, P2_RIGHT
	call KM_TEST_KEY
	jp nz, p2_move_right

	ld a, P2_FIRE
	call KM_TEST_KEY
	jp nz, p2_return_goal

return_p2:

	ret

; Player 1 movement
; -----------------
;
p1_move_up:

	ld a, (game_state + P1_Y)			; Check for edge of playing area
	cp a, 2
	jp z, return_p1					; If we are at the edge don't do anything

	ld a, (game_state + P1_X)			; Store the current location
	ld (game_state + P1_OLD_X), a
	ld a, (game_state + P1_Y)
	ld (game_state + P1_OLD_Y), a

	dec a								; Move
	ld (game_state + P1_Y), a
	ld a, CHR_UP						; Set player orientation character
	ld (game_state + P1_CHAR), a
	jp return_p1


p1_move_down:

	ld a, (game_state + P1_Y)			; Check for edge of playing area
	cp a, 22
	jp z, return_p1					; If we are at the edge don't do anything

	ld a, (game_state + P1_X)			; Store the current location
	ld (game_state + P1_OLD_X), a
	ld a, (game_state + P1_Y)
	ld (game_state + P1_OLD_Y), a

	inc a								; Move
	ld (game_state + P1_Y), a
	ld a, CHR_DOWN						; Set player orientation character
	ld (game_state + P1_CHAR), a
	jp return_p1

p1_move_left:

	ld a, (game_state + P1_X)			; Check for edge of playing area
	cp a, 2
	jp z,return_p1						; If we are at the edge don't do anything

	ld a, (game_state + P1_Y)			; Store the current location
	ld (game_state + P1_OLD_Y), a
	ld a, (game_state + P1_X)
	ld (game_state + P1_OLD_X), a

	dec a								; Move
	ld (game_state + P1_X), a
	ld a, CHR_LEFT						; Set player orientation character
	ld (game_state + P1_CHAR), a
	jp return_p1

p1_move_right:

	ld a, (game_state + P1_X)			; Check for edge of playing area
	cp a, 39
	jp z, return_p1					; If we are at the edge don't do anything

	ld a, (game_state + P1_Y)			; Store the current location
	ld (game_state + P1_OLD_Y), a
	ld a, (game_state + P1_X)
	ld (game_state + P1_OLD_X), a

	inc a								; Move
	ld (game_state + P1_X), a
	ld a, CHR_RIGHT						; Set player orientation character
	ld (game_state + P1_CHAR), a
	jp return_p1

p1_return_goal:

	ld a, (game_state + P1_X)			; Store the current location
	ld (game_state + P1_OLD_X), a
	ld a, (game_state + P1_Y)
	ld (game_state + P1_OLD_Y), a

	ld a, 2								; Return to goal
	ld (game_state + P1_X), a

	ld a, CHR_RIGHT						; Set player orientation character
	ld (game_state + P1_CHAR), a
	jp return_p1


; Player 2 movement
; -----------------
p2_move_up:

	ld a, (game_state + P2_Y)			; Check for edge of playing area
	cp a, 2
	jp z, return_p2					; If we are at the edge don't do anything

	ld a, (game_state + P2_X)			; Store the current location
	ld (game_state + P2_OLD_X), a
	ld a, (game_state + P2_Y)
	ld (game_state + P2_OLD_Y), a

	dec a								; Move
	ld (game_state + P2_Y), a
	ld a, CHR_UP						; Set player orientation character
	ld (game_state + P2_CHAR), a
	jp return_p2

p2_move_down:

	ld a, (game_state + P2_Y)			; Check for edge of playing area
	cp a, 22
	jp z, return_p2					; If we are at the edge don't do anything

	ld a, (game_state + P2_X)			; Store the current location
	ld (game_state + P2_OLD_X), a
	ld a, (game_state + P2_Y)
	ld (game_state + P2_OLD_Y), a

	inc a								; Move
	ld (game_state + P2_Y), a
	ld a, CHR_DOWN						; Set player orientation character
	ld (game_state + P2_CHAR), a
	jp return_p2

p2_move_left:

	ld a, (game_state + P2_X)			; Check for edge of playing area
	cp a, 2
	jp z,return_p2						; If we are at the edge don't do anything

	ld a, (game_state + P2_Y)			; Store the current location
	ld (game_state + P2_OLD_Y), a
	ld a, (game_state + P2_X)
	ld (game_state + P2_OLD_X), a

	dec a								; Move
	ld (game_state + P2_X), a
	ld a, CHR_LEFT						; Set player orientation character
	ld (game_state + P2_CHAR), a
	jp return_p2


p2_move_right:

	ld a, (game_state + P2_X)			; Check for edge of playing area
	cp a, 39
	jp z, return_p2					; If we are at the edge don't do anything

	ld a, (game_state + P2_Y)			; Store the current location
	ld (game_state + P2_OLD_Y), a
	ld a, (game_state + P2_X)
	ld (game_state + P2_OLD_X), a

	inc a								; Move
	ld (game_state + P2_X), a
	ld a, CHR_RIGHT						; Set player orientation character
	ld (game_state + P2_CHAR), a
	jp return_p2

p2_return_goal:

	ld a, (game_state + P2_X)			; Store the current location
	ld (game_state + P2_OLD_X), a
	ld a, (game_state + P2_Y)
	ld (game_state + P2_OLD_Y), a

	ld a, 2								; Return to goal
	ld (game_state + P2_X), a

	ld a, CHR_LEFT						; Set player orientation character
	ld (game_state + P1_CHAR), a
	jp return_p1
