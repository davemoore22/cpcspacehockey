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
; Handle main game loop
;###############################################################################

main_loop:
	ld	de, timer		; Check for game over (timer expired)
	ld	hl, time_game_over
	ld	b, TIME_DIGITS
	call	bcd_compare
	ret z				; Otherwise continue

	call	refresh_game		; Redraw any changable game elements

	call	handle_p1		; Move P1 if movement requested
	call	handle_p2		; Move P2 if movement requested


	call	set_cd_vars		; Handle collision detection
	call	test_cd_vars		; Can set the Adjacent flags

	cp	#FF			
	jr	nz, main_loop_cont	


	call	test_for_cd		; Check if P1 or P2 are adjacent to the
					; Ball after the movement above
	call	move_ball		; Move the Ball if needed
	call	check_goal

main_loop_cont:
	ld de,	timer			; Decrement the timer
	ld hl,	time_decrement
	ld b,	TIME_DIGITS
	call	bcd_subtract
	jp	main_loop		; Loop

;###############################################################################
; Display title screen
;###############################################################################

show_title:
	call	SCR_RESET		; Initialise and clear the screen
	call	SCR_CLEAR
	ld	a,1			; Set screen mode
	call	SCR_SET_MODE
	ld	bc, #0B0B		; Set border colour
	call	SCR_SET_BORDER
	ld	a, 1			; Set pen and paper
	call	TXT_SET_PEN
	ld	a, 0
	call	TXT_SET_PAPER

	ld	hl, #0802		; Display title text
	call	TXT_SET_CURSOR
	ld	hl, str_title
	call	print_string

	ld	a, 2			; Display credits
	call	TXT_SET_PEN
	ld	hl, #0304
	call	TXT_SET_CURSOR
	ld	hl, str_credits_1
	call	print_string
	ld	hl, #0205
	call	TXT_SET_CURSOR
	ld	hl, str_credits_2
	call	print_string

	ld	a, 1			; Display ready message
	call	TXT_SET_PEN
	ld	hl, #0717
	call	TXT_SET_CURSOR
	ld	hl, str_start_game
	call	print_string

	ret

;###############################################################################
; Title screen keyboard loop
;###############################################################################

wait_for_key:
	ld	a, P1_FIRE		; Check for P1/P2 fire
	call	KM_TEST_KEY
	jr	nz, wait_for_key_cont
	ld	a, P2_FIRE
	call	KM_TEST_KEY
	jr	nz, wait_for_key_cont

	ld	a, KEY_QUIT		; Check for Q to quit
	call	KM_TEST_KEY
	jr	nz, wait_for_key_quit

	jr	wait_for_key		; Loop around

; If we do not want to quit, return from this with quit flag unset
wait_for_key_cont:
	ld	a, 0			
	ld	(quit_flag), a
	ret

; If we want to quit, return from this with quit flag set
wait_for_key_quit:
	ld	a, #FF						
	ld	(quit_flag), a
	ret

;###############################################################################
; Setup User-Defined Characters using the Firmware
;###############################################################################

setup_udc:
	ld	de, UDC_FIRST		; Set the start of the UDCs
	ld	hl, matrix_table
	call	TXT_SET_M_TABLE

	ld	a, CHR_BANNER		; Load the UDCs starting from UDC_FIRST
	ld	hl, udc_banner
	call	TXT_SET_MATRIX
	ld	a, CHR_UP
	ld	hl, udc_player_up
	call	TXT_SET_MATRIX
	ld	a, CHR_DOWN
	ld	hl, udc_player_down
	call	TXT_SET_MATRIX
	ld	a, CHR_LEFT
	ld	hl, udc_player_left
	call	TXT_SET_MATRIX
	ld	a, CHR_RIGHT
	ld	hl, udc_player_right
	call	TXT_SET_MATRIX
	ld	a, CHR_BALL
	ld	hl, udc_ball
	call	TXT_SET_MATRIX
 	ret

;###############################################################################
; Clear and initialise game state
;###############################################################################

initalise:	
	ld	hl, timer		; Store the initial timer value
	ld	(hl), 0			
	inc	hl
	ld	(hl), TIME_MSB

; This is also called after a goal is scored
reset_pb:
	ld	ix, game_state		
	ld	(ix + P1_Y), 16		; Initial data for P1
	ld	(ix + P1_X), 5
	ld	(ix + P1_OLD_Y), 16
	ld	(ix + P1_OLD_X), 5
	ld	(ix + P1_CHAR), CHR_RIGHT
	ld 	(ix + P1_SCORE), 0
	ld	(ix + P2_Y), 5		; Initial data for P2
	ld	(ix + P2_X), 35
	ld	(ix + P2_OLD_Y), 5
	ld	(ix + P2_OLD_X), 35
	ld	(ix + P2_CHAR), CHR_LEFT
	ld	(ix + P2_SCORE), 0
	ld	(ix + BALL_OLD_Y), 11	; Initial Ball position
	ld	(ix + BALL_OLD_X), 20
	ld 	(ix + BALL_Y), 11
	ld	(ix + BALL_X), 20

	ret

;###############################################################################
; Draw game UI
;###############################################################################

refresh_ui:
	call	MC_WAIT_FLYBACK		; Wait for flyback to avoid flicker
	call	SCR_CLEAR

	; Set inks
	ld	a, 0			
	ld	b, 0
	ld	c, 0
	call	SCR_SET_INK
	ld	a, 1
	call	TXT_SET_PEN
	ld	a, 0
	call	TXT_SET_PAPER

	; Draw the goals
	ld	a, CHR_GOALS		
	ld	hl, #0105
	call	TXT_SET_CURSOR
	ld	a, CHR_GOALS
	call	TXT_OUTPUT
	ld	hl, #2805
	call	TXT_SET_CURSOR
	ld	a, CHR_GOALS
	call	TXT_OUTPUT
	ld	hl, #0111
	call	TXT_SET_CURSOR
	ld	a, CHR_GOALS
	call	TXT_OUTPUT
	ld	hl, #2811
	call	TXT_SET_CURSOR
	ld	a, CHR_GOALS
	call	TXT_OUTPUT

	; Draw bottom HUD
	ld	a, CHR_BANNER		
	ld	b, 40
	ld	hl, #0117

refresh_ui_loop:
	push	hl
	push	bc
	call	TXT_SET_CURSOR
	ld	a, CHR_BANNER
	call	TXT_OUTPUT
	pop	bc
	pop	hl
	inc	h
	djnz	refresh_ui_loop

	ld	hl, #0818
	call	TXT_SET_CURSOR
	ld	hl, str_bottom_text
	call	print_string

	; Draw scores
	ld	hl, #0419						
	call	TXT_SET_CURSOR
	ld	hl, str_game_score_p1
	call	print_string
	ld	hl, #1C19
	call	TXT_SET_CURSOR
	ld	hl, str_game_score_p2
	call	print_string

	; Draw initial time
	ld	hl, #1219						
	call	TXT_SET_CURSOR
	ld	de, timer
	ld	b, TIME_DIGITS
	call	bcd_show

	ret

;###############################################################################
; Show the game over screen
;###############################################################################

show_game_over:
	call	SCR_CLEAR		; Clear the screen
	ld	a, 1			; Set pen and paper
	call	TXT_SET_PEN
	ld	a, 0
	call	TXT_SET_PAPER

	; Display game over message
	ld	hl, #0D02
	call	TXT_SET_CURSOR
	ld	hl, str_game_over
	call	print_string

	; Display player scores
	ld	a, 3			
	call	TXT_SET_PEN
	ld	hl, #0F08
	call	TXT_SET_CURSOR
	ld	hl, str_p1_name
	call	print_string
	ld	a, 1
	call	TXT_SET_PEN
	ld	hl, #0F0A
	call	TXT_SET_CURSOR
	ld	hl, str_p2_name
	call	print_string

	; Display play again message
	ld	a, 1								
	call	TXT_SET_PEN
	ld	hl, #0517
	call	TXT_SET_CURSOR
	ld	hl, str_play_again
	call	print_string

	ret

;###############################################################################
; Update any game elements (such as player or ball positions) that might change
;###############################################################################

refresh_game
	call	MC_WAIT_FLYBACK		; Wait for flyback to avoid flicker

	; Draw timer
	ld	a, 1								
	call	TXT_SET_PEN
	ld	hl, #1219
	call	TXT_SET_CURSOR
	ld	de, timer
	ld	b, TIME_DIGITS
	call	bcd_show

	; Erase and redraw the Ball
	call	TXT_SET_PEN
	ld	hl, (game_state + BALL_OLD_Y)
	call	TXT_SET_CURSOR
	ld	a, CHR_SPACE
	call	TXT_OUTPUT
	ld	a, 2								
	call	TXT_SET_PEN
	ld	hl, (game_state + BALL_Y)
	call	TXT_SET_CURSOR
	ld	a, CHR_BALL
	call	TXT_OUTPUT

	; Erase and redraw P1
	ld	a, 3			
	call	TXT_SET_PEN
	ld	hl, (game_state + P1_OLD_Y)
	call	TXT_SET_CURSOR
	ld	a, CHR_SPACE
	call	TXT_OUTPUT
	ld	a, 3				
	call	TXT_SET_PEN
	ld	hl, (game_state + P1_Y)
	call	TXT_SET_CURSOR
	ld	a, (game_state + P1_CHAR)
	call	TXT_OUTPUT

	; Erase and redraw P2
	ld	a, 3								
	call	TXT_SET_PEN
	ld	hl, (game_state + P2_OLD_Y)
	call	TXT_SET_CURSOR
	ld	a, CHR_SPACE
	call	TXT_OUTPUT
	ld	a, 1								
	call	TXT_SET_PEN
	ld	hl, (game_state + P2_Y)
	call	TXT_SET_CURSOR
	ld	a, (game_state + P2_CHAR)
	call	TXT_OUTPUT

	ret



;###############################################################################
; Move the Ball depending on how it has been touched
;###############################################################################

move_ball:
	ld	hl, cd_state + 4	; Return if cd flags are both not set
	ld	a, (hl)
	cp	#FF
	jr	z, move_ball_c
	inc	hl
	ld	a, (hl)
	cp	#FF
	jr	z, move_ball_c
	ret

; A Player is adjacent to the ball, so work out how to move the ball
move_ball_c:

	; These all set E to #FF if ball moved
	call	move_ball_e		
	call	move_ball_w
	call	move_ball_n
	call	move_ball_s

	ld	a, e
	cp	#FF
	ret nz

	; call	check_for_goal


	ret

;###############################################################################
; See if a Goal being scored by checking the Ball coordinates
; 
; IF g%<2 AND h%<17 AND h%>5 THEN P1 Scores
; IF g%>39 AND h%<17 AND h%>5 THEN P2 Scores
;###############################################################################

; This is only called once the ball has been moved
check_for_goal:

check_for_goal_x1:
	ld 	a, (game_state + BALL_X)
	cp	a, 2
	jr	nc, check_for_goal_x2
	ld	a, 2
	ld 	(game_state + BALL_X), a
check_for_goal_x2:
	ld 	a, (game_state + BALL_X)
	cp	a, 38
	jr	c, check_for_goal_y1
	ld	a, 38
	ld 	(game_state + BALL_X), a
check_for_goal_y1:
	ld 	a, (game_state + BALL_Y)
	cp	a, 2
	jr	nc, check_for_goal_y2
	ld	a, 2
	ld 	(game_state + BALL_Y), a
check_for_goal_y2:
	ld 	a, (game_state + BALL_Y)
	cp	a, 21
	ret	c
	ld	a, 21
	ld 	(game_state + BALL_Y), a
	ret

;###############################################################################
; Move the Ball to the East if we can, if it has been nudged by either Player
; 
; IF x%=g%-1 AND y%=h% OR a%=g%-1 AND b%=h% THEN g%=g%+5
;
; Output:	E = #FF if Ball moved, else E = #00
;###############################################################################

move_ball_e:
move_ball_e_p1:
	ld	e, 0			; Clear exit condition

	; Check if P1_X = BALL_X - 1
	ld	a, (game_state + P1_X)
	ld	b, a
	ld	a, (game_state + BALL_X)
	sub	b
	cp	1
	jr	nz, move_ball_e_p2

	; Check if P1_Y = BALL_Y
	ld	a, (game_state + P1_Y)
	ld 	b, a
	ld	a, (game_state + BALL_Y)
	cp	b
	jr	nz, move_ball_e_p2

	ld	e, #FF			; If both, P1 is adjacent

move_ball_e_p2:
	; Check if P2_X = BALL_X - 1
	ld	a, (game_state + P2_X)
	ld 	b, a
	ld	a, (game_state + BALL_X)
	sub	b
	cp	1
	jr	nz, move_ball_e_cont

	; Check if P2_Y = BALL_Y
	ld	a, (game_state + P2_Y)
	ld	b, a
	ld	a, (game_state + BALL_Y)
	cp	b
	jr	nz, move_ball_e_cont

	ld	e, #FF			; If both, P2 is adjacent

move_ball_e_cont:
	; Return if neither of these conditions are met
	ld	a, e			
	cp	#FF
	ret	nz

	; Otherwise we can move the Ball
	ld	b, 5
	ld	c, 0
	call	mve_ball
	call	chk_clp_ball		; Clamp the Ball if necessary
	ld	e, #FF			; Signal that we have moved the Ball

move_ball_e_ret:
	ret

;###############################################################################
; Move the Ball to the West if we can, if it has been nudged by either Player
; 
; IF x%=g%+1 AND y%=h% OR a%=g%+1 AND b%=h% THEN g%=g%-5
;
; Output:	E = #FF if Ball moved, else E = #00
;###############################################################################

move_ball_w:
move_ball_w_p1:
	ld	e, 0			; Clear exit condition

	; Check if P1_X = BALL_X + 1
	ld	a, (game_state + BALL_X)
	ld	b, a
	ld	a, (game_state + P1_X)
	sub	b
	cp	1
	jr	nz, move_ball_w_p2

	; Check if P1_Y = BALL_Y
	ld	a, (game_state + P1_Y)
	ld 	b, a
	ld	a, (game_state + BALL_Y)
	cp	b
	jr	nz, move_ball_w_p2

	ld	e, #FF			; If both, P1 is adjacent

move_ball_w_p2:
	; Check if P2_X = BALL_X + 1
	ld	a, (game_state + BALL_X)
	ld 	b, a
	ld	a, (game_state + P2_X)
	sub	b
	cp	1
	jr	nz, move_ball_w_cont

	; Check if P2_Y = BALL_Y
	ld	a, (game_state + P2_Y)
	ld	b, a
	ld	a, (game_state + BALL_Y)
	cp	b
	jr	nz, move_ball_w_cont

	ld	e, #FF			; If both, P2 is adjacent

move_ball_w_cont:
	; Return if neither of these conditions are met
	ld	a, e			
	cp	#FF
	ret	nz

	; Otherwise we can move the Ball
	ld	a, (game_state + BALL_X)
	cp	5			; Avoid signed subtraction so if BALL_X - 5 < 0 then instead
					; set it to 3 and don't subtract 5
	jr	c, move_ball_w_sub_5
	sub	5
	jr	move_ball_w_store
move_ball_w_sub_5:
	ld	a, 3
move_ball_w_store:
	ld	(game_state + BALL_X), a 
		
	call	chk_clp_ball		; Clamp the Ball if necessary
	ld	e, #FF			; Signal that we have moved the Ball

move_ball_w_ret:
	ret

;###############################################################################
; Move the Ball to the North if we can, if it has been nudged by either Player
; 
; IF x%=g% AND y%=h%+1 OR a%=g% AND b%=h%+1 THEN h%=h%-5
;
; Output:	E = #FF if Ball moved, else E = #00
;###############################################################################

move_ball_n:
move_ball_n_p1:
	ld	e, 0			; Clear exit condition

	; Check if P1_Y = BALL_Y + 1
	ld	a, (game_state + BALL_Y)
	ld	b, a
	ld	a, (game_state + P1_Y)
	sub	b
	cp	1
	jr	nz, move_ball_n_p2

	; Check if P1_X = BALL_X
	ld	a, (game_state + P1_X)
	ld 	b, a
	ld	a, (game_state + BALL_X)
	cp	b
	jr	nz, move_ball_n_p2

	ld	e, #FF			; If both, P1 is adjacent

move_ball_n_p2:
	; Check if P2_Y = BALL_Y + 1
	ld	a, (game_state + BALL_Y)
	ld 	b, a
	ld	a, (game_state + P2_Y)
	sub	b
	cp	1
	jr	nz, move_ball_n_cont

	; Check if P2_X = BALL_X
	ld	a, (game_state + P2_X)
	ld	b, a
	ld	a, (game_state + BALL_X)
	cp	b
	jr	nz, move_ball_n_cont

	ld	e, #FF			; If both, P2 is adjacent

move_ball_n_cont:
	; Return if neither of these conditions are met
	ld	a, e			
	cp	#FF
	ret	nz

	; Otherwise we can move the Ball
	ld	a, (game_state + BALL_Y)
	cp	5			; Avoid signed subtraction so if BALL_X - 5 < 0 then instead
					; set it to 3 and don't subtract 5
	jr	c, move_ball_n_sub_5
	sub	5
	jr	move_ball_n_store
move_ball_n_sub_5:
	ld	a, 2
move_ball_n_store:
	ld	(game_state + BALL_Y), a 
		
	call	chk_clp_ball		; Clamp the Ball if necessary
	ld	e, #FF			; Signal that we have moved the Ball

move_ball_n_ret:
	ret

;###############################################################################
; Move the Ball to the South if we can, if it has been nudged by either Player
; 
; IF x%=g% AND y%=h%-1 OR a%=g% AND b%=h%-1 THEN h%=h%+5
;
; Output:	E = #FF if Ball moved, else E = #00
;###############################################################################

move_ball_s:
move_ball_s_p1:
	ld	e, 0			; Clear exit condition

	; Check if P1_Y = BALL_Y - 1
	ld	a, (game_state + P1_Y)
	ld	b, a
	ld	a, (game_state + BALL_Y)
	sub	b
	cp	1
	jr	nz, move_ball_s_p2

	; Check if P1_X = BALL_X
	ld	a, (game_state + P1_X)
	ld 	b, a
	ld	a, (game_state + BALL_X)
	cp	b
	jr	nz, move_ball_s_p2

	ld	e, #FF			; If both, P1 is adjacent

move_ball_s_p2:
	; Check if P2_Y = BALL_Y - 1
	ld	a, (game_state + P2_Y)
	ld 	b, a
	ld	a, (game_state + BALL_Y)
	sub	b
	cp	1
	jr	nz, move_ball_s_cont

	; Check if P2_X = BALL_X
	ld	a, (game_state + P2_X)
	ld	b, a
	ld	a, (game_state + BALL_X)
	cp	b
	jr	nz, move_ball_s_cont

	ld	e, #FF			; If both, P2 is adjacent

move_ball_s_cont:
	; Return if neither of these conditions are met
	ld	a, e			
	cp	#FF
	ret	nz

	; Otherwise we can move the Ball
	ld	b, 0
	ld	c, 5
	call	mve_ball
	call	chk_clp_ball		; Clamp the Ball if necessary
	ld	e, #FF			; Signal that we have moved the Ball

move_ball_s_ret:
	ret


;###############################################################################
; Check the Ball Position and keep it in bounds, clamping it to the edge of the
; playing area
; 
; IF g%>38 THEN g%=38
; IF g%<2 THEN g%=2
; IF h%>21 THEN h%=21
; IF h%<2 THEN h%=2
;
;###############################################################################

; This is only called once the ball has been moved
chk_clp_ball:
chk_clp_ball_x1:
	ld 	a, (game_state + BALL_X)
	cp	a, 1
	jr	nc, chk_clp_ball_x2
	ld	a, 1
	ld 	(game_state + BALL_X), a
chk_clp_ball_x2:
	ld 	a, (game_state + BALL_X)
	cp	a, 40
	jr	c, chk_clp_ball_y1
	ld	a, 40
	ld 	(game_state + BALL_X), a
chk_clp_ball_y1:
	ld 	a, (game_state + BALL_Y)
	cp	a, 2
	jr	nc, chk_clp_ball_y2
	ld	a, 2
	ld 	(game_state + BALL_Y), a
chk_clp_ball_y2:
	ld 	a, (game_state + BALL_Y)
	cp	a, 21
	ret	c
	ld	a, 21
	ld 	(game_state + BALL_Y), a

	ret

;###############################################################################
; Move the ball (will not move it so that any x/y is negative though)
;
; INPUT:	B = x squares to move (signed) (will be -5, 0, or 5)
; INPUT:	C = y squares to move (signed) (will be -5, 0, or 5)
; OUTPUT:	E = #FF if ball moved
;###############################################################################

mve_ball:
	ld	e, 0
mve_ball_x:
	ld	a, b			; Skip if no movement for this axis
	cp	0
	jr	z, mve_ball_y

mve_ball_x_minus_5:
	cp	a, #FA			; If -5
	jr	nz, mve_ball_x_plus_5
	ld	a, (game_state + BALL_X)
	ld	(game_state + BALL_OLD_X), a
	sub	a, 5
	ld	(game_state + BALL_X), a
	ld	e, #FF
	jr	mve_ball_y
mve_ball_x_plus_5:
	cp	a, 5			; If 5
	jr	nz, mve_ball_y
	ld	a, (game_state + BALL_X)
	ld	(game_state + BALL_OLD_X), a
	add	a, 5
	ld	(game_state + BALL_X), a
	ld	e, #FF
	jr	mve_ball_y

mve_ball_y:
	ld	a, c			; Skip if no movement for this axis
	cp	0
	ret	z

mve_ball_y_minus_5:
	cp	a, #FA			; If -5
	jr	nz, mve_ball_y_plus_5
	ld	a, (game_state + BALL_Y)
	ld	(game_state + BALL_OLD_Y), a
	sub	a, 5
	ld	(game_state + BALL_Y), a
	ld	e, #FF
	ret
mve_ball_y_plus_5:
	cp	a, 5			; If 5
	jr	nz, mve_ball_y
	ld	a, (game_state + BALL_Y)
	ld	(game_state + BALL_OLD_Y), a
	add	a, 5
	ld	(game_state + BALL_Y), a
	ld	e, #FF
	ret

; IF x%=g%+1 AND y%=h%-1 OR a%=g%+1 AND b%=h%-1 THEN g%=g%+5:h%=h%+5
; IF x%=g%+1 AND y%=h%+1 OR a%=g%+1 AND b%=h%+1 THEN g%=g%-5:h%=h%-5
; IF x%=g%-1 AND y%=h%+1 OR a%=g%-1 AND b%=h%+1 THEN g%=g%+5:h%=h%-5

;###############################################################################
; See if we need to move the ball, will check the bytes populated in set_cd_vars
; and if both ABS(P1 bytes) = 0 or 1, set the P1 adjacent flag; and similiarly 
; for P2; if either adjacent flag is set, return A = #FF, else A = 0
;
; Corrupts:	AF, BC, DE, HL
;###############################################################################
test_cd_vars:

	ld	de, col_det_state + 4	; Load P1 Adjacent Flag
	ld	bc, col_det_state + 0	; Load P1_Y_diff

	call	test_cd_vars_inner	; Set A = #FF if ABS(BC) = 0 or 1
	ld	h, a
	inc	bc			; Load P1_X_diff
	call	test_cd_vars_inner	; Set A = #FF if ABS(BC) = 0 or 1
	ld	l, a
	call	check_hl_for_both_ff
	ld	(de), a

	inc	de			; Load P1 Adjacent Flag
	inc	bc			

	call	test_cd_vars_inner	; Set A = #FF if ABS(BC) = 0 or 1
	ld	h, a
	inc	bc			; Load P2_X_diff
	call	test_cd_vars_inner	; Set A = #FF if ABS(BC) = 0 or 1
	ld	l, a
	call	check_hl_for_both_ff
	ld	(de), a

	 push	bc
	ld hl, #1701
	call	TXT_SET_CURSOR
	ld a, (col_det_state + 4)
	call	print_int
	ld hl, #1702
	call	TXT_SET_CURSOR
	ld a, (col_det_state + 5)
	call	print_int
	pop	bc




	;ld	hl, col_det_state + 4
	;call	check_hl_for_ff		; Set A = #FF if either is #FF

	;push	bc	
	;ld 	hl, #1701
	;call	TXT_SET_CURSOR
	;call	print_int
	;pop	bc

	ret

test_cd_vars_inner:
	ld	a, (bc)			
	call	find_abs_a		; Get the ABS(byte) into A
	cp	2			; Is it 0 or 1?
	ret	z			
	ret	nc
	ld	a, #FF			; Set the Flag is its 0 or 1

	ret

;###############################################################################
; To aid us in collision detection, we store the distance from each Player to
; the Ball every time a Player moves. This will also clear the Player Adjacent
; flags at col_det_state + 4 and col_det_state + 5 as well
;###############################################################################
set_cd_vars:
	ld	b, 6			; Reset the game data
	ld	hl, col_det_state
	ld	a, 0
set_cd_vars_loop:
	ld	(hl), 0
	inc	hl
	djnz	set_cd_vars_loop

	; P1
	ld	hl, col_det_state	; HL points to the 4 storage bytes	
	ld	a, (game_state + BALL_Y)
	ld	b, a
	ld	a, (game_state + P1_Y)
	sub	b
	ld	(hl), a

	inc	hl
	ld	a, (game_state + BALL_X)
	ld	b, a
	ld	a, (game_state + P1_X)
	sub	b
	ld	(hl), a

	; P2	
	inc	hl
	ld	a, (game_state + BALL_Y)
	ld	b, a
	ld	a, (game_state + P2_Y)
	sub	b
	ld	(hl), a

	inc	hl
	ld	a, (game_state + BALL_X)
	ld	b, a
	ld	a, (game_state + P2_X)
	sub	b
	ld	(hl), a

	ret

;###############################################################################
; Test for Collision Detection
;
; If P1 or P2 is adjacent to the Ball then set the Collision Bytes
;###############################################################################

test_for_cd:
	ld	b, 6			; Reset the game data
	ld	hl, cd_state
	ld	a, 0
test_for_cd_loop:
	ld	(hl), 0
	inc	hl
	djnz	test_for_cd_loop

	call	get_p1_pos		; Get the distance from each player to
					; the ball - note that ABS(distance) is
					; stored at collision_state
	call	get_p2_pos

	; Check if P1 is adjacent to the ball
	ld	hl, cd_state		
	call	test_for_cd_adj
	ret	z			; Return early if not 0 or 1
	ret	nc
	inc hl
	call	test_for_cd_adj
	ret	z			; Return early if not 0 or 1
	ret	nc:
	ld	a, (hl)							
	cp	2
	ret

	ld	hl, cd_state + 4	; P1 is adjacent to the ball so flag it
	ld	(hl), #FF

	; Check if P2 is adjacent to the ball
	ld	hl, cd_state + 2			
	call	test_for_cd_adj
	ret	z			; Return early if not 0 or 1
	ret	nc
	ld	hl, cd_state + 3
	call	test_for_cd_adj
	ret	z			; Return early if not 0 or 1
	ret	nc
	
	ld	hl, cd_state + 5	; P2 is adjacent to the ball so flag it
	ld	(hl), #FF

	ret

test_for_cd_adj:
					
	cp	2
	ret

;###############################################################################
; Work out the position of P1 relative to the Ball calls ABS(A-B) for Player 1 X
; and Y coordinates against the Ball position
;###############################################################################

get_p1_pos:
	ld	a, (game_state + BALL_Y)
	ld	b, a
	ld	a, (game_state + P1_Y)
	call	find_abs		
	ld	(cd_state), a

	ld	a, (game_state + BALL_X)			
	ld	b, a
	ld	a, (game_state + P1_X)
	call	find_abs			
	ld	(cd_state + 1), a

	ret

;###############################################################################
; Work out the position of P2 relative to the Ball calls ABS(A-B) for Player 2 X
; and Y coordinates against the Ball position
;###############################################################################
get_p2_pos:

	ld	a, (game_state + BALL_Y)
	ld	b, a
	ld	a, (game_state + P2_Y)
	call	find_abs
	ld	(cd_state + 2), a

	ld	a, (game_state + BALL_X)			
	ld	b, a
	ld	a, (game_state + P2_X)
	call	find_abs
	ld	(cd_state + 3), a

	ret

;###############################################################################
; Check for a goal being scored
;###############################################################################

check_goal: ; #TODO
	ret


;###############################################################################
; Check for any inputs for Player 1 using Firmware Calls
;###############################################################################

handle_p1:
	ld	a, P1_UP			
	call	KM_TEST_KEY
	jp	nz, handle_p1_up

	ld	a, P1_DOWN
	call	KM_TEST_KEY
	jp 	nz, handle_p1_down

	ld	a, P1_LEFT
	call	KM_TEST_KEY
	jp	nz, handle_p1_left

	ld	a, P1_RIGHT
	call	KM_TEST_KEY
	jp	nz, handle_p1_right

	ld	a, P1_FIRE
	call	KM_TEST_KEY
	jp	nz, handle_p1_goal

handle_p1_ret:				; Exit point for the movement routines
	ret

;###############################################################################
; Check for any inputs for Player 2 using Firmware Calls
;###############################################################################

handle_p2:
	ld	a, P2_UP						
	call	KM_TEST_KEY
	jp	nz, handle_p2_up

	ld	a, P2_DOWN
	call	KM_TEST_KEY
	jp	nz, handle_p2_down

	ld	a, P2_LEFT
	call	KM_TEST_KEY
	jp	nz, handle_p2_left

	ld	a, P2_RIGHT
	call	KM_TEST_KEY
	jp	nz, handle_p2_right

	ld	a, P2_FIRE
	call	KM_TEST_KEY
	jp	nz, handle_p2_goal

handle_p2_ret:				; Exit point for the movement routines
	ret

;###############################################################################
; Player Movement Routines
;###############################################################################

handle_p1_up:
	ld	a, (game_state + P1_Y)	; Check for edge of playing area
	cp	a, 1
	jp	z, handle_p1_ret	; If we are at the edge don't do anything

	ld	a, (game_state + P1_X)	; Store the current location
	ld	(game_state + P1_OLD_X), a
	ld	a, (game_state + P1_Y)
	ld	(game_state + P1_OLD_Y), a

	dec	a			; Move
	ld	(game_state + P1_Y), a
	ld	a, CHR_UP		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	handle_p1_ret

handle_p1_down:
	ld	a, (game_state + P1_Y)	; Check for edge of playing area
	cp	a, 22
	jp	z, handle_p1_ret	; If we are at the edge don't do anything

	ld	a, (game_state + P1_X)	; Store the current location
	ld	(game_state + P1_OLD_X), a
	ld	a, (game_state + P1_Y)
	ld	(game_state + P1_OLD_Y), a

	inc	a			; Move
	ld	(game_state + P1_Y), a
	ld	a, CHR_DOWN		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	handle_p1_ret

handle_p1_left:
	ld	a, (game_state + P1_X)	; Check for edge of playing area
	cp	a, 2
	jp	z,handle_p1_ret	; If we are at the edge don't do anything

	ld	a, (game_state + P1_Y)	; Store the current location
	ld	(game_state + P1_OLD_Y), a
	ld	a, (game_state + P1_X)
	ld	(game_state + P1_OLD_X), a

	dec	a			; Move
	ld	(game_state + P1_X), a
	ld	a, CHR_LEFT		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	handle_p1_ret

handle_p1_right:
	ld	a, (game_state + P1_X)	; Check for edge of playing area
	cp	a, 39
	jp	z, handle_p1_ret	; If we are at the edge don't do anything

	ld	a, (game_state + P1_Y)	; Store the current location
	ld	(game_state + P1_OLD_Y), a
	ld	a, (game_state + P1_X)
	ld	(game_state + P1_OLD_X), a

	inc	a			; Move
	ld	(game_state + P1_X), a
	ld	a, CHR_RIGHT		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	handle_p1_ret

handle_p1_goal:
	ld	a, (game_state + P1_X)	; Store the current location
	ld	(game_state + P1_OLD_X), a
	ld	a, (game_state + P1_Y)
	ld	(game_state + P1_OLD_Y), a

	ld	a, 2			; Return to goal
	ld	(game_state + P1_X), a

	ld	a, CHR_RIGHT		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	handle_p1_ret

handle_p2_up:
	ld	a, (game_state + P2_Y)	; Check for edge of playing area
	cp	a, 2
	jp	z, handle_p2_ret		; If we are at the edge don't do anything

	ld	a, (game_state + P2_X)	; Store the current location
	ld	(game_state + P2_OLD_X), a
	ld	a, (game_state + P2_Y)
	ld	(game_state + P2_OLD_Y), a

	dec	a			; Move
	ld	(game_state + P2_Y), a
	ld	a, CHR_UP		; Set player orientation character
	ld	(game_state + P2_CHAR), a
	jp	handle_p2_ret

handle_p2_down:
	ld	a, (game_state + P2_Y)	; Check for edge of playing area
	cp	a, 22
	jp	z, handle_p2_ret		; If we are at the edge don't do anything

	ld	a, (game_state + P2_X)	; Store the current location
	ld	(game_state + P2_OLD_X), a
	ld	a, (game_state + P2_Y)
	ld	(game_state + P2_OLD_Y), a

	inc	a			; Move
	ld	(game_state + P2_Y), a
	ld	a, CHR_DOWN		; Set player orientation character
	ld	(game_state + P2_CHAR), a
	jp	handle_p2_ret

handle_p2_left:
	ld	a, (game_state + P2_X)	; Check for edge of playing area
	cp	a, 2
	jp	z,handle_p2_ret		; If we are at the edge don't do anything

	ld	a, (game_state + P2_Y)	; Store the current location
	ld	(game_state + P2_OLD_Y), a
	ld	a, (game_state + P2_X)
	ld	(game_state + P2_OLD_X), a

	dec	a			; Move
	ld	(game_state + P2_X), a
	ld	a, CHR_LEFT		; Set player orientation character
	ld	(game_state + P2_CHAR), a
	jp	handle_p2_ret

handle_p2_right:
	ld	a, (game_state + P2_X)	; Check for edge of playing area
	cp	a, 39
	jp	z, handle_p2_ret		; If we are at the edge don't do anything

	ld	a, (game_state + P2_Y)	; Store the current location
	ld	(game_state + P2_OLD_Y), a
	ld	a, (game_state + P2_X)
	ld	(game_state + P2_OLD_X), a

	inc	a			; Move
	ld	(game_state + P2_X), a
	ld	a, CHR_RIGHT		; Set player orientation character
	ld	(game_state + P2_CHAR), a
	jp	handle_p2_ret

handle_p2_goal:
	ld	a, (game_state + P2_X)	; Store the current location
	ld	(game_state + P2_OLD_X), a
	ld	a, (game_state + P2_Y)
	ld	(game_state + P2_OLD_Y), a

	ld	a, 2			; Return to goal
	ld	(game_state + P2_X), a

	ld	a, CHR_LEFT		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	handle_p2_ret
