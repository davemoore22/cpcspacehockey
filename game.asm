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

; Handle main game loop
; ---------------------
main_game_loop:

	ld de, time_left					; Check for game over (i.e. main timer expired)
	ld hl, time_game_over
	ld b, TIME_DIGITS
	call _bcd_compare
	ret z

	call refresh_game_screen			; Otherwise continue
	call handle_input_p1
	call handle_input_p2
	call check_collision_detection
	call move_ball
	call check_for_goal_scored

	ld de, time_left					; Decrement the timer
	ld hl, time_decrement
	ld b, TIME_DIGITS
	call _bcd_subtract

	jp main_game_loop

; Display title screen
; --------------------
show_title_screen:

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
	call print_string

	ld a, 2								; Display credits
	call TXT_SET_PEN
	ld hl, #0304
	call TXT_SET_CURSOR
	ld hl, str_credits_1
	call print_string
	ld hl, #0205
	call TXT_SET_CURSOR
	ld hl, str_credits_2
	call print_string

	ld a, 1								; Display ready message
	call TXT_SET_PEN
	ld hl, #0717
	call TXT_SET_CURSOR
	ld hl, str_start_game
	call print_string

	ret

; Title screen keyboard loop
; --------------------------
wait_for_keys:

	ld a, P1_FIRE						; Check for P1/P2 fire
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

		ld a, #FF						; If we want to quit, return from this with quit flag set
		ld (quit_flag), a
		ret

	continue:

		ld a, 0
		ld (quit_flag), a
		ret

; Setup UDCs
; ----------
setup_udcs:

	ld de, UDC_FIRST					; Set the start of the UDCs
	ld hl, matrix_table
	call TXT_SET_M_TABLE

	ld a, CHR_BANNER					; Load the UDCs starting from UDC_FIRST
	ld hl, udc_banner
	call TXT_SET_MATRIX

	ld a, CHR_UP
	ld hl, udc_player_up
	call TXT_SET_MATRIX

	ld a, CHR_DOWN
	ld hl, udc_player_down
	call TXT_SET_MATRIX

	ld a, CHR_LEFT
	ld hl, udc_player_left
	call TXT_SET_MATRIX

	ld a, CHR_RIGHT
	ld hl, udc_player_right
	call TXT_SET_MATRIX

	ld a, CHR_BALL
	ld hl, udc_ball
	call TXT_SET_MATRIX

 	ret

; Clear and setup game state
; --------------------------
initalise_game_state:

	ld ix, time_left					; Store the initial timer value
	ld (ix), 0
	ld (ix + 1), TIME_MSB

	reset_player_and_ball_positions:

		ld ix, game_state				; Initial data for P1
		ld (ix + P1_Y), 16
		ld (ix + P1_X), 5
		ld (ix + P1_OLD_Y), 16
		ld (ix + P1_OLD_X), 5
		ld (ix + P1_CHAR), CHR_RIGHT
		ld (ix + P1_SCORE), 0

		ld (ix + P2_Y), 5				; Initial data for P2
		ld (ix + P2_X), 35
		ld (ix + P2_OLD_Y), 5
		ld (ix + P2_OLD_X), 35
		ld (ix + P2_CHAR), CHR_LEFT
		ld (ix + P2_SCORE), 0

		ld (ix + BALL_OLD_Y), 11		; Initial Ball position
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
	call print_string

	ld hl, #0419						; Draw scores
	call TXT_SET_CURSOR
	ld hl, str_game_score_p1
	call print_string

	ld hl, #1C19
	call TXT_SET_CURSOR
	ld hl, str_game_score_p2
	call print_string

	ld hl, #1219						; Draw initial time
	call TXT_SET_CURSOR
	ld de, time_left
	ld b, TIME_DIGITS
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
	call print_string

	ld a, 3								; Display scores
	call TXT_SET_PEN
	ld hl, #0F08
	call TXT_SET_CURSOR
	ld hl, str_p1_name
	call print_string

	ld a, 1
	call TXT_SET_PEN
	ld hl, #0F0A
	call TXT_SET_CURSOR
	ld hl, str_p2_name
	call print_string

	ld a, 1								; Display play again message
	call TXT_SET_PEN
	ld hl, #0517
	call TXT_SET_CURSOR
	ld hl, str_play_again
	call print_string

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
	ld b, TIME_DIGITS
	call _bcd_show

	ld a, 3								; Erase Ball
	call TXT_SET_PEN
	ld hl, (game_state + BALL_OLD_Y)
	call TXT_SET_CURSOR
	ld a, CHR_SPACE
	call TXT_OUTPUT

	ld a, 2								; Draw Ball
	call TXT_SET_PEN
	ld ix, game_state
	ld hl, (game_state + BALL_Y)
	call TXT_SET_CURSOR
	ld a, CHR_BALL
	call TXT_OUTPUT

	ld a, 3								; Erase P1
	call TXT_SET_PEN
	ld hl, (game_state + P1_OLD_Y)
	call TXT_SET_CURSOR
	ld a, CHR_SPACE
	call TXT_OUTPUT

	ld a, 3								; Draw P1
	call TXT_SET_PEN
	ld hl, (game_state + P1_Y)
	call TXT_SET_CURSOR
	ld a, (game_state + P1_CHAR)
	call TXT_OUTPUT

	ld a, 3								; Erase P2
	call TXT_SET_PEN
	ld hl, (game_state + P2_OLD_Y)
	call TXT_SET_CURSOR
	ld a, CHR_SPACE
	call TXT_OUTPUT

	ld a, 1								; Draw P2
	call TXT_SET_PEN
	ld hl, (game_state + P2_Y)
	call TXT_SET_CURSOR
	ld a, (game_state + P2_CHAR)
	call TXT_OUTPUT

	ret

; Move the Ball depending on how it has been touched
; --------------------------------------------------
move_ball:

	call check_move_ball_east			; Sets E to #FF if ball moved
	
	ret

; IF x%=g%-1 AND y%=h% OR a%=g%-1 AND b%=h% THEN g%=g%+5
; IF g%>38 THEN g%=38
check_move_ball_east:

	ld e, 0								; Clear exit condition

	ld ix, game_state					; Check if P1_X = BALL_X - 1
	ld a, (ix + BALL_X)
	ld b, (ix + P1_X)
	sub b
	cp 1
	jp nz, check_p2_move_ball_e

	ld ix, game_state					; Check if P1_Y = BALL_Y
	ld a, (ix + BALL_Y)
	ld b, (ix + P1_Y)
	sub b
	cp 0
	jp nz, check_p2_move_ball_e

	ld e, #FF							; If so, we are adjacent

	check_p2_move_ball_e:

		ld ix, game_state				; Check if P2_X = BALL_X - 1
		ld a, (ix + BALL_X)
		ld b, (ix + P2_X)
		sub b
		cp 1
		jp nz, continue_ball_e

		ld ix, game_state				; Check if P2_Y = BALL_Y
		ld a, (ix + BALL_Y)
		ld b, (ix + P2_Y)
		sub b
		cp 0
		jp nz, continue_ball_e

		ld e, #FF

	continue_ball_e:

		ld a, e							; Return if neither of these conditions are met
		cp #FF
		ret nz

		ld a, (game_state + BALL_X)		; Otherwise move the Ball
		add a, 5
		ld (game_state + BALL_X), a 
		
		cp a, 38						; Don't let the Ball go off the edge of the playing area
		jr c, return_ball_e
		ld a, 38
		ld (game_state + BALL_X), a		; Clamp value to 38 (-1 than last columkn of playing area)
		ld e, #FF

	return_ball_e:

	ret

; IF x%=g%+1 AND y%=h% OR a%=g%+1 AND b%=h% THEN g%=g%-5
	; IF x%=g% AND y%=h% OR a%=g%+1 AND b%=h%-1 THEN h%=h%+5
	; IF x%=g% AND y%=h%+1 OR a%=g% AND b%=h%+1 THEN h%=h%-5

	; IF x%=g%-1 AND y%=h%-1 OR a%=g%-1 AND b%=h%-1 THEN g%=g%+5:h%=h%+5
	; IF x%=g%+1 AND y%=h%-1 OR a%=g%+1 AND b%=h%-1 THEN g%=g%+5:h%=h%+5
	; IF x%=g%+1 AND y%=h%+1 OR a%=g%+1 AND b%=h%+1 THEN g%=g%-5:h%=h%-5
	; IF x%=g%-1 AND y%=h%+1 OR a%=g%-1 AND b%=h%+1 THEN g%=g%+5:h%=h%-5

; Check for collision detection between the Ball and P1/P2
; --------------------------------------------------------
;
; if P1 or P2 is adjacent to the Ball then move it away in the opposite direction
check_collision_detection:

	ld b, 6								; Reset
	ld ix, collision_state
	ld a, 0

	reset_loop:

		ld (ix), 0
		inc ix
		djnz reset_loop

	call calculate_p1_position			; Get the distance from each player to the ball
	call calculate_p2_position			; ABS(distance) stored in bytes at collision_state

	ld ix, collision_state				; Check if P1 is adjacent to the ball
	call check_player_adjacent
	ret z								; Return early if not 0 or 1
	ret nc
	inc ix
	call check_player_adjacent
	ret z								; Return early if not 0 or 1
	ret nc

	ld ix, collision_state + 4			; P1 is adjacent to the ball so flag it
	ld ix, #FF

	ld ix, collision_state + 2			; Check if P2 is adjacent to the ball
	call check_player_adjacent
	ret z								; Return early if not 0 or 1
	ret nc
	ld ix, collision_state + 3
	call check_player_adjacent
	ret z								; Return early if not 0 or 1
	ret nc
	
	ld ix, collision_state + 5			; P2 is adjacent to the ball so flag it
	ld ix, #FF

	ret

	check_player_adjacent:

		ld a, (ix)							
		cp 2
		ret
	
; Work out the position of P1 relative to the Ball
calculate_p1_position:

	ld a, (game_state + BALL_Y)
	ld b, a
	ld a, (game_state + P1_Y)
	call _find_abs_diff_numbers			; Equivalent of ABS(A-B)
	ld (collision_state), a

	ld a, (game_state + BALL_X)			
	ld b, a
	ld a, (game_state + P1_X)
	call _find_abs_diff_numbers			
	ld (collision_state + 1), a

	ret

; Work out the position of P2 relative to the Ball
calculate_p2_position:

	ld a, (game_state + BALL_Y)
	ld b, a
	ld a, (game_state + P2_Y)
	call _find_abs_diff_numbers
	ld (collision_state + 2), a

	ld a, (game_state + BALL_X)			
	ld b, a
	ld a, (game_state + P2_X)
	call _find_abs_diff_numbers
	ld (collision_state + 3), a

	ret

; Check for a goal being scored
check_for_goal_scored:


	ret


; Check for any inputs
; --------------------
handle_input_p1:

	ld a, P1_UP							; Check for P1 controls
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

		ret

handle_input_p2:

	ld a, P2_UP						; Check for P2 controls
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

; P1 movement
;------------
p1_move_up:

	ld a, (game_state + P1_Y)			; Check for edge of playing area
	cp a, 2
	jp z, return_p1						; If we are at the edge don't do anything

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
	jp z, return_p1						; If we are at the edge don't do anything

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
	jp z, return_p1						; If we are at the edge don't do anything

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


; P2 movement
; -----------
p2_move_up:

	ld a, (game_state + P2_Y)			; Check for edge of playing area
	cp a, 2
	jp z, return_p2						; If we are at the edge don't do anything

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
	jp z, return_p2						; If we are at the edge don't do anything

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
	jp z, return_p2						; If we are at the edge don't do anything

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
