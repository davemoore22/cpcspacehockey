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
; Game Strings
;###############################################################################

str_bottom_text:	DEFM 'S P A C E - H O C K E Y', #00
str_credits_1:		DEFM 'Original (c) David Hay 1988 (AA42)', #00
str_credits_2:		DEFM 'Assembly Rewrite (c) Dave Moore 2023', #00
str_game_over:		DEFM 'G A M E  O V E R', #00
str_game_score_p1:	DEFM '1:', #00
str_game_score_p2:	DEFM '2:', #00
str_p1_name:		DEFM 'Player 1: 00', #00
str_p2_name:		DEFM 'Player 2: 00', #00
str_play_again:		DEFM '<FIRE> OR <SPACE> TO PLAY AGAIN', #00
str_start_game:		DEFM '<FIRE> OR <SPACE> TO START', #00
str_title:		DEFM 'S P A C E - H O C K E Y', #00

;###############################################################################
; User Defined Characters
;###############################################################################

udc_banner:		DEFB 24, 60, 102, 195, 192, 0, 0, 0
udc_player_up:		DEFB 0, 24, 60, 36, 102, 102, 255, 219
udc_player_down:	DEFB 219, 255, 102, 102, 36, 60, 24, 0
udc_player_left:	DEFB 3, 15, 62, 99, 99, 62, 15, 3
udc_player_right:	DEFB 192, 240, 124, 198, 198, 124, 240, 192
udc_ball:		DEFB 0, 24, 44, 94, 126, 60, 24, 0








