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
; Corrupts:	AF, BC, DE, HL
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
	jr	nz, .continue

	ld	ix, col_det_state + 0	
	call	do_move			; Move the Ball as a result of P1 Move
	cp	a, e
	cp	#FF
	jr	z, .continue		; If P1 has already moved the Ball, skip

	ld	ix, col_det_state + 2	
	call	do_move			; Move the Ball as a result of P2 Move

.continue:
	ld de,	timer			; Decrement the timer
	ld hl,	time_decrement
	ld b,	TIME_DIGITS
	call	bcd_subtract
	jp	main_loop		; Loop

;###############################################################################
;
; Display title screen
;
; Corrupts:	AF, BC, HL
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
; Corrupts:	AF
;
;###############################################################################

wait_for_key:
	ld	a, P1_FIRE		; Check for P1/P2 fire
	call	KM_TEST_KEY
	jr	nz, .continue
	ld	a, P2_FIRE
	call	KM_TEST_KEY
	jr	nz, .continue

	ld	a, KEY_QUIT		; Check for Q to quit
	call	KM_TEST_KEY
	jr	nz, .quit

	jr	wait_for_key		; Loop around

; If we do not want to quit, return from this with quit flag unset
.continue:
	ld	a, 0
	ld	(quit_flag), a
	ret

; If we want to quit, return from this with quit flag set
.quit:
	ld	a, #FF
	ld	(quit_flag), a
	ret

;###############################################################################
;
; Setup User-Defined Characters using the Firmware
; 
; Corrupts:	AF, DE, HL
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
; Setup Window Streams
; 
; Corrupts:	AF, DE, HL
;
;###############################################################################

setup_streams:
	ld	a, 1			; Switch to Stream #1
	call	TXT_STR_SELECT	
	ld	h, 1
	ld	d, 39
	ld	l, 2
	ld	e, 21
	call	TXT_WIN_ENABLE		; Define a Window over the Playing Area
					; as Stream #1
	ld	a, 0
	call	TXT_SET_PAPER			
	ld	a, 0			; Swap back to the default Stream (#0)
	call	TXT_STR_SELECT
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
	ld	ix, game_state
	ld 	(ix + P1_SCORE), 0
	ld	(ix + P2_SCORE), 0
	

; This is also called after a goal is scored
reset_game_state:
	ld	ix, game_state
	ld	(ix + P1_Y), 16		; Initial data for P1
	ld	(ix + P1_X), 5
	ld	(ix + P1_CHAR), CHR_RIGHT
	ld	(ix + P2_Y), 5		; Initial data for P2
	ld	(ix + P2_X), 35
	ld	(ix + P2_CHAR), CHR_LEFT
	ld 	(ix + BALL_Y), 11	; Initial Ball position
	ld	(ix + BALL_X), 20
	ld	(ix + P1_OLD_Y), 16
	ld	(ix + P1_OLD_X), 5
	ld	(ix + P2_OLD_Y), 5
	ld	(ix + P2_OLD_X), 35
	ld	(ix + BALL_OLD_Y), 11	
	ld	(ix + BALL_OLD_X), 20

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

.loop:
	push	hl
	push	bc
	call	TXT_SET_CURSOR
	ld	a, CHR_BANNER
	call	TXT_OUTPUT
	pop	bc
	pop	hl
	inc	h
	djnz	.loop

	ld	hl, #0818
	call	TXT_SET_CURSOR
	ld	hl, str_bottom_text
	call	print_string

	; Draw scores
	ld	hl, #0419
	call	TXT_SET_CURSOR
	ld	hl, str_game_score_p1
	call	print_string
	ld	hl, #2419
	call	TXT_SET_CURSOR
	ld	hl, str_game_score_p2
	call	print_string

	ld	hl, #0719
	call	TXT_SET_CURSOR
	ld	a, (game_state + P1_SCORE)
	call	print_int

	ld	hl, #2019
	call	TXT_SET_CURSOR
	ld	a, (game_state + P2_SCORE)
	call	print_int

	; Draw time
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
; Corrupts:	AF, HL
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
	ld	hl, #1908
	call	TXT_SET_CURSOR
	ld	a, (game_state + P1_SCORE)
	call	print_int


	ld	a, 1
	call	TXT_SET_PEN
	ld	hl, #0F0A
	call	TXT_SET_CURSOR
	ld	hl, str_p2_name
	call	print_string
	ld	hl, #190A
	call	TXT_SET_CURSOR
	ld	a, (game_state + P2_SCORE)
	call	print_int

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

	; Clear Playing Area
	; call	clear_playing_area

	; Draw Timer
	ld	a, 1
	call	TXT_SET_PEN
	ld	hl, #1219
	call	TXT_SET_CURSOR
	ld	de, timer
	ld	b, TIME_DIGITS
	call	bcd_show

	; Draw scores
	ld	hl, #0719
	call	TXT_SET_CURSOR
	ld	a, (game_state + P1_SCORE)
	call	print_int
	ld	hl, #2019
	call	TXT_SET_CURSOR
	ld	a, (game_state + P2_SCORE)
	call	print_int

	; Erase and redraw Ball
	ld	a, 3
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
; Corrupts:	AF
;
;###############################################################################

handle_p1:

	ld	a, RESET_KEY
	call	KM_TEST_KEY
	jp	nz, .return_ball

	ld	a, P1_UP
	call	KM_TEST_KEY
	jp	nz, .up

	ld	a, P1_DOWN
	call	KM_TEST_KEY
	jp 	nz, .down

	ld	a, P1_LEFT
	call	KM_TEST_KEY
	jp	nz, .left

	ld	a, P1_RIGHT
	call	KM_TEST_KEY
	jp	nz, .right

	ld	a, P1_FIRE
	call	KM_TEST_KEY
	jp	nz, .goal

.return:				; Exit point for the movement routines
	ret

.up:
	ld	a, (game_state + P1_Y)	; Check for edge of playing area
	cp	a, 1
	jp	z, .return		; If we are at the edge don't do anything

	ld	a, (game_state + P1_X)	; Store the current location
	ld	(game_state + P1_OLD_X), a
	ld	a, (game_state + P1_Y)
	ld	(game_state + P1_OLD_Y), a

	dec	a			; Move
	ld	(game_state + P1_Y), a
	ld	a, CHR_UP		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	.return

.down:
	ld	a, (game_state + P1_Y)	; Check for edge of playing area
	cp	a, 22
	jp	z, .return		; If we are at the edge don't do anything

	ld	a, (game_state + P1_X)	; Store the current location
	ld	(game_state + P1_OLD_X), a
	ld	a, (game_state + P1_Y)
	ld	(game_state + P1_OLD_Y), a

	inc	a			; Move
	ld	(game_state + P1_Y), a
	ld	a, CHR_DOWN		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	.return

.left:
	ld	a, (game_state + P1_X)	; Check for edge of playing area
	cp	a, 2
	jp	z, .return		; If we are at the edge don't do anything

	ld	a, (game_state + P1_Y)	; Store the current location
	ld	(game_state + P1_OLD_Y), a
	ld	a, (game_state + P1_X)
	ld	(game_state + P1_OLD_X), a

	dec	a			; Move
	ld	(game_state + P1_X), a
	ld	a, CHR_LEFT		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	.return

.right:
	ld	a, (game_state + P1_X)	; Check for edge of playing area
	cp	a, 39
	jp	z, .return		; If we are at the edge don't do anything

	ld	a, (game_state + P1_Y)	; Store the current location
	ld	(game_state + P1_OLD_Y), a
	ld	a, (game_state + P1_X)
	ld	(game_state + P1_OLD_X), a

	inc	a			; Move
	ld	(game_state + P1_X), a
	ld	a, CHR_RIGHT		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	.return

.goal:
	ld	a, (game_state + P1_X)	; Store the current location
	ld	(game_state + P1_OLD_X), a
	ld	a, (game_state + P1_Y)
	ld	(game_state + P1_OLD_Y), a

	ld	a, 2			; Return to goal
	ld	(game_state + P1_X), a

	ld	a, CHR_RIGHT		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	.return

.return_ball:
	call	reset_game_state
	call	refresh_ui
	jp	.return

;###############################################################################
;
; Check for any inputs for Player 2 using Firmware Calls
;
; Corrupts:	AF
;
;###############################################################################

handle_p2:
	ld	a, P2_UP
	call	KM_TEST_KEY
	jp	nz, .up

	ld	a, P2_DOWN
	call	KM_TEST_KEY
	jp	nz, .down

	ld	a, P2_LEFT
	call	KM_TEST_KEY
	jp	nz, .left

	ld	a, P2_RIGHT
	call	KM_TEST_KEY
	jp	nz, .right

	ld	a, P2_FIRE
	call	KM_TEST_KEY
	jp	nz, .goal

.return:				; Exit point for the movement routines
	ret

.up:
	ld	a, (game_state + P2_Y)	; Check for edge of playing area
	cp	a, 1
	jp	z, .return		; If we are at the edge don't do anything

	ld	a, (game_state + P2_X)	; Store the current location
	ld	(game_state + P2_OLD_X), a
	ld	a, (game_state + P2_Y)
	ld	(game_state + P2_OLD_Y), a

	dec	a			; Move
	ld	(game_state + P2_Y), a
	ld	a, CHR_UP		; Set player orientation character
	ld	(game_state + P2_CHAR), a
	jp	.return

.down:
	ld	a, (game_state + P2_Y)	; Check for edge of playing area
	cp	a, 22
	jp	z, .return		; If we are at the edge don't do anything

	ld	a, (game_state + P2_X)	; Store the current location
	ld	(game_state + P2_OLD_X), a
	ld	a, (game_state + P2_Y)
	ld	(game_state + P2_OLD_Y), a

	inc	a			; Move
	ld	(game_state + P2_Y), a
	ld	a, CHR_DOWN		; Set player orientation character
	ld	(game_state + P2_CHAR), a
	jp	.return

.left:
	ld	a, (game_state + P2_X)	; Check for edge of playing area
	cp	a, 2
	jp	z,.return		; If we are at the edge don't do anything

	ld	a, (game_state + P2_Y)	; Store the current location
	ld	(game_state + P2_OLD_Y), a
	ld	a, (game_state + P2_X)
	ld	(game_state + P2_OLD_X), a

	dec	a			; Move
	ld	(game_state + P2_X), a
	ld	a, CHR_LEFT		; Set player orientation character
	ld	(game_state + P2_CHAR), a
	jp	.return

.right:
	ld	a, (game_state + P2_X)	; Check for edge of playing area
	cp	a, 39
	jp	z, .return		; If we are at the edge don't do anything

	ld	a, (game_state + P2_Y)	; Store the current location
	ld	(game_state + P2_OLD_Y), a
	ld	a, (game_state + P2_X)
	ld	(game_state + P2_OLD_X), a

	inc	a			; Move
	ld	(game_state + P2_X), a
	ld	a, CHR_RIGHT		; Set player orientation character
	ld	(game_state + P2_CHAR), a
	jp	.return

.goal:
	ld	a, (game_state + P2_X)	; Store the current location
	ld	(game_state + P2_OLD_X), a
	ld	a, (game_state + P2_Y)
	ld	(game_state + P2_OLD_Y), a

	ld	a, 2			; Return to goal
	ld	(game_state + P2_X), a

	ld	a, CHR_LEFT		; Set player orientation character
	ld	(game_state + P1_CHAR), a
	jp	.return

.return_ball:
	call	reset_game_state
	call	refresh_ui
	jp	.return

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

	call	.inner			; Set A = #FF if ABS(BC) = 0 or 1
	ld	h, a
	inc	bc			; Load P1_X_diff
	call	.inner			; Set A = #FF if ABS(BC) = 0 or 1
	ld	l, a
	call	check_hl_for_both_ff
	ld	(de), a

	inc	de			; Load P2 Adjacent Flag
	inc	bc			; Load P2_Y_diff

	call	.inner			; Set A = #FF if ABS(BC) = 0 or 1
	ld	h, a
	inc	bc			; Load P2_X_diff
	call	.inner			; Set A = #FF if ABS(BC) = 0 or 1
	ld	l, a
	call	check_hl_for_both_ff
	ld	(de), a

	ld	hl, (col_det_state + 4)	; Set A = #FF if either is #FF
	call	check_hl_for_ff
	ret

.inner:
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
.loop:
	ld	(hl), 0
	inc	hl
	djnz	.loop

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
; The Ball is moved, and if a goal is scored, points are added as appropriate
; and the Game Field is reset.
;
; Input:	IX = col_det_state_p1_y for P1 or col_det_state_p2_y for P2
; Output:	E = #FF is ball has been moved else #00
; Corrupts:	AF, BC, DE
;
;###############################################################################

do_move:
	ld 	d, (IX + 0)		; Y
	ld 	e, (IX + 1)		; X

.test_s:
	ld	a, d
	cp	-1			; P_Y = BALL_Y - 1
	jr	nz, .test_n
	ld	a, e
	cp	0			; P_X = BALL_X
	jp	nz, .test_n
	jp 	.move_s

.test_n:
	ld	a, d			; P_Y = BALL_Y + 1
	cp	1
	jr	nz, .test_w
	ld	a, e
	cp	0			; P_X = BALL_X
	jp	nz, .test_w
	jp 	.move_n

.test_w:
	ld	a, d			; P_Y = BALL_Y
	cp	0
	jr	nz, .test_e
	ld	a, e
	cp	1			; P_X = BALL_X + 1
	jp	nz, .test_e
	jp 	.move_w

.test_e:
	ld	a, d
	cp	0			; P_Y = BALL_Y
	jr	nz, .test_ne
	ld	a, e
	cp	-1			; P_X = BALL_X - 1
	jp	nz, .test_ne
	jp 	.move_e

.test_ne:
	ld	a, d
	cp	1			; P_Y = BALL_Y + 1
	jr	nz, .test_nw
	ld	a, e
	cp	-1			; P_X = BALL_X - 1
	jp	nz, .test_nw
	jp 	.move_ne

.test_nw:
	ld	a, d
	cp	1			; P_Y = BALL_Y + 1
	jr	nz, .test_se
	ld	a, e
	cp	1			; P_X = BALL_X + 1
	jp	nz, .test_se
	jp 	.move_nw

.test_se:
	ld	a, d
	cp	-1			; P_Y = BALL_Y - 1
	jr	nz, .test_sw
	ld	a, e
	cp	-1			; P_X = BALL_X + 1
	jp	nz, .test_sw
	jp 	.move_se

.test_sw:
	ld	a, d
	cp	-1			; P_Y = BALL_Y - 1
	jr	nz, .test_ret
	ld	a, e
	cp	1			; P_X = BALL_X - 1
	jp	nz, .test_ret
	jp 	.move_sw

.test_ret:
	ld	e, #00
	ret

.move_n:
	ld	b, 0			; Move Ball North
	ld	c, -5
	call	move_ball
	call 	play_ball_sound
	call	check_for_goal		; Need to set flag if goal scored and exit out of movement
	cp 	#FF

	call	check_clip_ball
	ld	e, #FF
	ret

.move_s:
	ld	b, 0			; Move Ball South
	ld	c, 5
	call	move_ball
	call 	play_ball_sound
	call	check_for_goal
	cp 	#FF
	call	nz, check_clip_ball
	ld	e, #FF
	ret

.move_e:
	ld	b, 5			; Move Ball East
	ld	c, 0
	call	move_ball
	call 	play_ball_sound
	call	check_for_goal
	cp 	#FF
	call	nz, check_clip_ball
	ld	e, #FF
	ret

.move_w:
	ld	b, -5			; Move Ball West
	ld	c, 0
	call	move_ball
	call 	play_ball_sound
	call	check_for_goal
	cp 	#FF
	call	nz, check_clip_ball
	ld	e, #FF
	ret

.move_ne:
	ld	b, 5			; Move Ball North-East
	ld	c, -5
	call	move_ball
	call 	play_ball_sound
	call	check_for_goal		; Need to set flag if goal scored and exit out of movement
	cp 	#FF

	call	check_clip_ball
	ld	e, #FF
	ret

.move_nw:
	ld	b, -5			; Move Ball North-East
	ld	c, -5
	call	move_ball
	call 	play_ball_sound
	call	check_for_goal		; Need to set flag if goal scored and exit out of movement
	cp 	#FF

	call	check_clip_ball
	ld	e, #FF
	ret

.move_se:
	ld	b, 5			; Move Ball South
	ld	c, 5
	call	move_ball
	call 	play_ball_sound
	call	check_for_goal
	cp 	#FF
	call	nz, check_clip_ball
	ld	e, #FF
	ret

.move_sw:
	ld	b, -5			; Move Ball South
	ld	c, 5
	call	move_ball
	call 	play_ball_sound
	call	check_for_goal
	cp 	#FF
	call	nz, check_clip_ball
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
; Corrupts:	AF, BC, DE
;
;###############################################################################

move_ball:
	ld	e, 0
.x:
	ld	a, b			; Skip if no movement for this axis
	cp	0
	jr	z, .y

.x_minus_5:
	cp	-5			; If -5
	jr	nz, .x_plus_5
	ld	a, (game_state + BALL_X)
	ld	(game_state + BALL_OLD_X), a
	sub	a, 5
	ld	(game_state + BALL_X), a
	ld	e, #FF
	jr	.y

.x_plus_5:
	cp	5			; If 5
	jr	nz, .y
	ld	a, (game_state + BALL_X)
	ld	(game_state + BALL_OLD_X), a
	add	a, 5
	ld	(game_state + BALL_X), a
	ld	e, #FF
	jr	.y

.y:
	ld	a, c			; Skip if no movement for this axis
	cp	0
	ret	z

.y_minus_5:
	cp	-5			; If -5
	jr	nz, .y_plus_5
	ld	a, (game_state + BALL_Y)
	ld	(game_state + BALL_OLD_Y), a
	sub	a, 5
	ld	(game_state + BALL_Y), a
	ld	e, #FF
	ret

.y_plus_5:
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

check_clip_ball:
.x1:
	ld 	a, (game_state + BALL_X)
	cp	3
	jp 	m, .x1_set		; If A < 3, set it to 3
	jr	.x2
.x1_set:
	ld	a, 3
	ld 	(game_state + BALL_X), a
	jr	.y1

.x2:
	ld 	a, (game_state + BALL_X)
	cp	38
	jp	m, .y1			; If A > 38, set it to 38
.x2_set:
	ld	a, 38
	ld 	(game_state + BALL_X), a
	jr	.y1

.y1:
	ld 	a, (game_state + BALL_Y)
	cp	2
	jp 	m, .y1_set		; If A < 2, set it to 2
	jr	.y2
.y1_set:
	ld	a, 2
	ld 	(game_state + BALL_Y), a
.y2:
	ld 	a, (game_state + BALL_Y)
	cp	21
	ret	m			; If A > 21, set it to 21
.y2_set:
	ld	a, 21
	ld 	(game_state + BALL_Y), a
	ret

;###############################################################################
;
; Check for a Goal, if so change the score and play a sound effect and then
; reset the playing field (P1 scores into the Goals on the right, and P2 scores
; into the Goals on the left).
;
; Corrupts:	AF, HL
; Output:	A = #FF if a goal has been scored, else A = #00
;
;###############################################################################

check_for_goal:

	ld	a, #00
	ld	a, (game_state + BALL_X)
	cp	2
	jp	p, .skip		
	jr	.lt_2			; If Ball is in P1 goal area

.skip:	
	ld	a, (game_state + BALL_X)
	cp	39
	ret	m
	jr	.gt_39			; If Ball is in P2 goal area
	
.lt_2:		
	ld	a, (game_state + BALL_Y); Check if inside goalposts on right
	cp	5
	ret	m
	cp	17
	jp	m, .p2_scored
	ret

.gt_39:		
	ld	a, (game_state + BALL_Y); Check if inside goalposts on P1_LEFT
	cp	5
	ret	m
	cp	17
	jp	m, .p1_scored
	ret

.p1_scored:
	ld	a, (game_state + P1_SCORE)
	inc	a
	ld 	(game_state + P1_SCORE), a
	call	play_goal_sound
	call	reset_game_state
	call	refresh_ui
	; call	clear_playing_area
	ld	a, #FF
	ret

.p2_scored:

	ld	a, (game_state + P2_SCORE)
	inc	a
	ld 	(game_state + P2_SCORE), a
	call	play_goal_sound
	call	reset_game_state
	call	refresh_ui
	; call	clear_playing_area
	ld	a, #FF
	ret


;###############################################################################
;
; Clear the Playing Area
;
; Corrupts:	AF
;
;
;###############################################################################

clear_playing_area:
	ld	a, 1			; Switch to Stream #1
	call	TXT_STR_SELECT
	call	TXT_CLEAR_WINDOW	; Clear it
	ld	a, 0
	call	TXT_STR_SELECT		; Switch back to Default Stream (#0)

	ret

;###############################################################################
;
; Play the Ball Hit Sound
;
; Corrupts:	HL
;
; https://tinyurl.com/2uu9h7ea
;
;###############################################################################

play_ball_sound:
	ld	hl, sound_ball
	call	SOUND_QUEUE
	ret
	
;###############################################################################
;
; Play the Goal Sound
;
; Corrupts:	AF, BC, DE, HL
;
; https://tinyurl.com/2uu9h7ea
;
;###############################################################################

play_goal_sound: 
	ld	b, 15			; Reset Noise Level
.loop:
	ld 	hl, sound_goal + 5
	ld	(hl), b
	push	bc
	ld	hl, sound_goal
	call	SOUND_QUEUE
	pop	bc
	call	MC_WAIT_FLYBACK
	djnz	.loop
	ld	b, 0
	ld	hl, sound_goal
	call	SOUND_QUEUE
	ret