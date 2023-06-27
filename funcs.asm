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
; Print a string
; Input: HL = address of string to print (terminated by 0)
;###############################################################################

print_string:
	ld	a, (hl)
	cp	0
	ret	z
	inc	hl
	call	TXT_OUTPUT
	jr	print_string

;###############################################################################
; Print a 3-digit decimal number
; Input: A = 8-bit value to display
; Routine from https://tinyurl.com/mr39uep5
;###############################################################################

print_dec_number:
	ld	b, 100			; Divisor to obtain 100's digit value
	call	print_dec_digit		; Display digit
	ld	b, 10			; Divisor to obtain 10's digit value
	call	print_dec_digit		; Display digit
	ld	b, 1			; Divisor to obtain 1's digit value

print_dec_digit:
	ld	c, 0			; Zeroise result

dec_divide:
	sub	b			; Subtract divisor
	jr 	c, display_dec_digit	; If dividend < divisor, division ended
	inc	c			; Increment digit value
	jr	dec_divide

display_dec_digit:
	add	a, b			; Add divisor because dividend was negative, leaving remainder
	push	af
	ld	a, c			; Get digit value
	add	a, '0'			; Convert value into ASCII character
	call	TXT_OUTPUT		; Display digit
	pop	af
	ret

; BCD Functions
;
; https://chibiakumas.com/z80/advanced.php

; Some of our commands need to start from the MSB, this routine will shift HL and DE along b bytes
_bcd_get_end:

	push bc
		ld c, b							; We want to add BC, but we need to number of bytes - 1
		dec c
		ld b, 0
		add hl, bc
		ex hl, de						; We've done HL, but we also want to do DE

		add hl, bc
		ex hl, de
	pop bc
	ret

_bcd_show:

	call _bcd_get_end					; Need to process from the end of the array

	_bcd_show_direct:

		ld a, (de)
		and %11110000					; Use the high nibble
		rrca
		rrca
		rrca
		rrca
		add '0'							; Convert to a letter and print it
		call TXT_OUTPUT
		ld a, (de)
		dec de
		and %00001111					; Now the low nibble
		add '0'
		call TXT_OUTPUT
		djnz _bcd_show_direct			; Next byte
		ret

_bcd_subtract:							; Clear carry flag

	or a

	_bcd_subtract_again:

		ld a, (de)
		sbc (hl)						; Subtract HL from DE with carry
		daa								; Fix A using DAA
		ld (de), a						; Store it

		inc de
		inc hl
		djnz _bcd_subtract_again
		ret

_bcd_add:

	or a								; Clear carry flag

	_bcd_add_again:

		ld a, (de)
		adc (hl)						; Add HL to DE with carry
		daa								; Fix A using DAA
		ld (de), a						; Store it

		inc de
		inc hl
		djnz _bcd_add_again
		ret

_bcd_compare:

	call _bcd_get_end

	_bcd_compare_direct:				; Start from MSB

		ld a, (de)
		cp (hl)
		ret c							; Smaller
		ret nz							; Greater
		dec de							; Equal so move onto next byte
		dec hl
		djnz _bcd_compare_direct
		or a 							; Clear the carry flag
		ret


_find_abs_diff_numbers:

	sub b								; A, B contain the numbers to compare
	or a
	ret p
	neg
    ret

_check_diff:							; Returns #FF in A if condition is met

	ld a, (ix)							; IX = Ball coordinate
	ld b, a	
	ld a, (iy)							; IY = Player coordinate
	sub b
	cp d								; D is difference to check against
	jr z, _set_equal
	ld a, #00
	ret

	_set_equal:
		ld a, #FF
		ret

_beep:

	ld a, 7
	call TXT_OUTPUT
	ret
	

