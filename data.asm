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

matrix_table:				; Space for UDCs
	DEFB 	0, 0, 0, 0, 0, 0
	DEFB 	0, 0, 0, 0, 0, 0
	DEFB 	0, 0, 0, 0, 0, 0
	DEFB 	0, 0, 0, 0, 0, 0
	DEFB 	0, 0, 0, 0, 0, 0
	DEFB 	0, 0, 0, 0, 0, 0
	DEFB 	0, 0, 0, 0, 0, 0
	DEFB 	0, 0, 0, 0, 0, 0

game_state:				; Space for game state
	DEFB 	0, 0, 0, 0, 0, 0	; P1 old_x/y, x/y, character, score
	DEFB 	0, 0, 0, 0, 0, 0	; P2 old_x/y, x/y, character, score
	DEFB 	0, 0, 0, 0		; Ball old_x/y, x/y
	
col_det_state:				; Colision Detection variables
	DEFB 	0, 0, 0, 0, 0, 0	; P1/P2 offset_y/x, P1/P2 adjacent flags

quit_flag:
	DEFB 	0			; Set to #FF if we want to quit

timer:					; Space for timer
	DEFB 	0, 0			; Time left (Packed BCD - 4 Digits)

time_decrement:
	DEFB 	1, 0			; Timer decrement

time_game_over:
	DEFB 	0, 0			; Game Over timer value

sound_ball:
	DEFB	1, 0, 0, 30, 0, 0
	DEFB  	12, 10, 0
