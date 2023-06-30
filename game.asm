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
; Handle main game loop
;
; Corrupts:	AF, BC, DE, HL (Obviously)
;
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
	call	test_cd_vars		; Skip if don't need to move the Ball
	cp	#FF
	jr	nz, main_loop_cont

	ld	ix, col_det_state + 0	; Ball moved as a result of P1
	call	do_move
	cp	a, e
	cp	#FF
	jr	z, main_loop_cont

	ld	ix, col_det_state + 2	; Ball moved as a result of P2
	call	do_move

main_loop_cont:
	ld de,	timer			; Decrement the timer
	ld hl,	time_decrement
	ld b,	TIME_DIGITS
	call	bcd_subtract
	jp	main_loop		; Loop

;###############################################################################
;
; Display title screen
;
; Corrupts:	AF, BC, DE, HL
;
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
;
; Title screen keyboard loop
;
; Output:	A = #FF if we want to quit, else #00 if we can continue
; Corrupts:	AF, BC, DE, HL
;
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
;
; Setup User-Defined Characters using the Firmware
; 
; Corrupts:	AF, BC, DE, HL
;
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
;
; Clear and initialise game state
;
; Corrupts:	IX, HL
; 
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
;
; Draw game UI
;
; Corrupts:	AF, BC, DE, HL
;
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
;
; Show the game over screen
;
; Corrupts:	AF, BC, DE, HL
;
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
;
; Update any game elements (such as player or ball positions) that might change
;
; Corrupts:	AF, DE, HL
;
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
;
; Check for any inputs for Player 1 using Firmware Calls
;
; Corrupts:	AF, HL
;
;###############################################################################

handle_p1:

	ld	a, RESET_KEY
	call	KM_TEST_KEY
	jp	nz, return_ball

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
;
; Check for any inputs for Player 2 using Firmware Calls
;
; Corrupts:	AF, HL
;
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
;
; Player Movement Routines
;
; Corrupts:	AF
;
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

return_ball:
	call	reset_pb
	jp	handle_p2_ret

;###############################################################################
;
; See if we need to move the ball, will check the bytes populated in set_cd_vars
; and if both ABS(P1 bytes) = 0 or 1, set the P1 adjacent flag; and similiarly
; for P2; if either adjacent flag is set, return A = #FF, else A = #00
;
; Output:	A = #FF or A = #00
; Corrupts:	AF, BC, DE, HL
;
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

	ld	hl, (col_det_state + 4)	; Set A = #FF if either is #FF
	call	check_hl_for_ff
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
;
; To aid us in collision detection, we store the distance from each Player to
; the Ball every time a Player moves. This will also clear the Player Adjacent
; flags at col_det_state + 4 and col_det_state + 5 as well.
;
; Corrupts:	AF, BC, HL
;
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
;
; Workout how to move the Ball after it has been touched. We test the offsets
; stored at col_det_state+0 to +3 to see which way we need to move the ball,
; starting with P1. Note that if P1 moves the ball we skip over checking for P2.
;
; Input:	IX = col_det_state_p1_y or col_det_state_p2_y
; Output:	E = #FF is ball has been moved else #00
; Corrupts:	AF, BC, DE, HL
;
;###############################################################################
do_move:
	ld 	d, (IX + 0)		; Y
	ld 	e, (IX + 1)		; X

do_move_test_s:
	ld	a, d
	cp	-1			; P_Y = BALL_Y - 1
	jr	nz, do_move_test_n
	ld	a, e
	cp	0			; P_X = BALL_X
	jp	nz, do_move_test_n
	jp 	do_move_s

do_move_test_n:
	ld	a, d			; P_Y = BALL_Y + 1
	cp	1
	jr	nz, do_move_test_w
	ld	a, e
	cp	0			; P_X = BALL_X
	jp	nz, do_move_test_w
	jp 	do_move_n

do_move_test_w:
	ld	a, d			; P_Y = BALL_Y
	cp	0
	jr	nz, do_move_test_e
	ld	a, e
	cp	1			; P_X = BALL_X + 1
	jp	nz, do_move_test_e
	jp 	do_move_w

do_move_test_e:
	ld	a, d
	cp	0			; P_Y = BALL_Y
	jr	nz, do_move_test_ne
	ld	a, e
	cp	-1			; P_X = BALL_X - 1
	jp	nz, do_move_test_ne
	jp 	do_move_e

do_move_test_ne:
	ld	e, #00
	ret ;#TODO

do_move_n:
	ld	b, 0			; Move Ball North
	ld	c, -5
	call	move_ball
	call    check_for_goal
	call	chk_clp_ball
	ld	e, #FF
	ret

do_move_s:
	ld	b, 0			; Move Ball South
	ld	c, 5
	call	move_ball
	call    check_for_goal
	call	chk_clp_ball
	ld	e, #FF
	ret

do_move_e:
	ld	b, 5			; Move Ball East
	ld	c, 0
	call	move_ball
	call    check_for_goal
	call	chk_clp_ball
	ld	e, #FF
	ret

do_move_w:
	ld	b, -5			; Move Ball West
	ld	c, 0
	call	move_ball
	call    check_for_goal
	call	chk_clp_ball
	ld	e, #FF
	ret

;###############################################################################
;
; Move the Ball (not clipped to the edge of the playing area)
;
; Input:	B = x squares to move (signed) (will be -5, 0, or 5)
; Input:	C = y squares to move (signed) (will be -5, 0, or 5)
; Output:	E = #FF if Ball moved, else #00 if Ball not moved
;
; Corrupts:	AF, BC, DE, HL
;
;###############################################################################

move_ball:
	ld	e, 0
move_ball_x:
	ld	a, b			; Skip if no movement for this axis
	cp	0
	jr	z, move_ball_y

move_ball_x_minus_5:
	cp	-5			; If -5
	jr	nz, move_ball_x_plus_5
	ld	a, (game_state + BALL_X)
	ld	(game_state + BALL_OLD_X), a
	sub	a, 5
	ld	(game_state + BALL_X), a
	ld	e, #FF
	jr	move_ball_y
move_ball_x_plus_5:
	cp	5			; If 5
	jr	nz, move_ball_y
	ld	a, (game_state + BALL_X)
	ld	(game_state + BALL_OLD_X), a
	add	a, 5
	ld	(game_state + BALL_X), a
	ld	e, #FF
	jr	move_ball_y

move_ball_y:
	ld	a, c			; Skip if no movement for this axis
	cp	0
	ret	z

move_ball_y_minus_5:
	cp	-5			; If -5
	jr	nz, move_ball_y_plus_5
	ld	a, (game_state + BALL_Y)
	ld	(game_state + BALL_OLD_Y), a
	sub	a, 5
	ld	(game_state + BALL_Y), a
	ld	e, #FF
	ret
move_ball_y_plus_5:
	cp	5			; If 5
	ret	nz
	ld	a, (game_state + BALL_Y)
	ld	(game_state + BALL_OLD_Y), a
	add	a, 5
	ld	(game_state + BALL_Y), a
	ld	e, #FF
	ret

;###############################################################################
;
; Check the Ball Position and keep it in bounds, clamping it to the edge of the
; playing area. This is only called once the ball has been moved and we are sure
; a goal has not been scored
;
;
; Corrupts:	AF
;
;###############################################################################
chk_clp_ball:
chk_clp_ball_x1:
	ld 	a, (game_state + BALL_X)
	cp	3
	jp 	m, chk_clp_ball_x1_set	; If A < 3, set it to 3
	jr	chk_clp_ball_x2
chk_clp_ball_x1_set:
	ld	a, 3
	ld 	(game_state + BALL_X), a
	jr	chk_clp_ball_y1

chk_clp_ball_x2:
	ld 	a, (game_state + BALL_X)
	cp	38
	jp	m, chk_clp_ball_y1	; If A > 38, set it to 38
chk_clp_ball_x2_set:
	ld	a, 38
	ld 	(game_state + BALL_X), a
	jr	chk_clp_ball_y1

chk_clp_ball_y1:
	ld 	a, (game_state + BALL_Y)
	cp	2
	jp 	m, chk_clp_ball_y1_set	; If A < 2, set it to 2
	jr	chk_clp_ball_y2
chk_clp_ball_y1_set:
	ld	a, 2
	ld 	(game_state + BALL_Y), a
chk_clp_ball_y2:
	ld 	a, (game_state + BALL_Y)
	cp	21
	ret	m			; If A > 21, set it to 21
chk_clp_ball_y2_set:
	ld	a, 21
	ld 	(game_state + BALL_Y), a
	ret

; # TODO
check_for_goal:

	ret