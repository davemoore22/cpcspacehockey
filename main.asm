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
; Space-Hockey
; Original (c) David Hay 1988 (AA42)
; Z80 Rewrite (c) Dave Moore 2023
;
; Example compilation and running with rasm and caprice32 under Linux:
;
; ../rasm/rasm_linux64 -eo ./main.asm
; ../caprice32/cap32 -a "MEMORY &7fff" -i ./hockey.bin -o 0x8000
;
;###############################################################################

; Info
PRINT
PRINT "S P A C E - H O C K E Y"
PRINT "Original (c) David Hay 1988 (AA42)"
PRINT "Assembly Rewrite (c) Dave Moore 2023"
PRINT

; Choose output type (Binary File/Disk Image/Tape Image)
DESTINATION = 1

; Set destination (code is completely relocatable)
BASE_LOAD_ADDRESS = #8000
PRINT "Base Load Address is", {hex}BASE_LOAD_ADDRESS

ORG     BASE_LOAD_ADDRESS
BEGIN_CODE

;###############################################################################
;
; Beginning of ASM
;
;###############################################################################

setup:
        call    setup_udc               ; Redefine characters
start_game:
        call    show_title              ; Title screen
        call    wait_for_key

        ld      a, (quit_flag)          ; Exit if Q key is pressed
        cp      #FF
        ret     z

restart_game:
        call    SCR_CLEAR
        call    initalise
        call    refresh_ui
        call    main_loop               ; Main game loop

        call    show_game_over          ; Game over screen
        call    wait_for_key

        ld      a, (quit_flag)          ; Exit if Q key is pressed
        cp      #FF
        ret     z

        jp      restart_game

; Include all the other game code/data
INCLUDE 'game.asm'
INCLUDE 'consts.asm'
INCLUDE 'strings.asm'
INCLUDE 'funcs.asm'
INCLUDE 'data.asm'

;###############################################################################
;
; End of ASM
;
;###############################################################################

END_CODE

; Output to Binary File, Disk Image, or Tape Image
IF DESTINATION == 1
        PRINT "Saving to Binary File"
        SAVE 'hockey.bin', BEGIN_CODE, END_CODE - BEGIN_CODE
        PRINT
ELSEIF DESTINATION == 2
        PRINT "Saving to Disk Image"
        SAVE 'hockey.bin', BEGIN_CODE, END_CODE - BEGIN_CODE, DSK, 'hockey.dsk'
        PRINT
ELSEIF DESTINATION == 3
        PRINT "Saving to Tape Image"
        SAVE 'hockey.bin', BEGIN_CODE, END_CODE - BEGIN_CODE, TAPE, 'hockey.cdt'
        PRINT
ENDIF
