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
;
; Input:	HL = address of string to print (terminated by 0)
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
;
; Input:	A = 8-bit value to display
;
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
	add	a, b			; Add divisor because dividend was
					; negative, leaving remainder
	push	af
	ld	a, c			; Get digit value
	add	a, '0'			; Convert value into ASCII character
	call	TXT_OUTPUT		; Display digit
	pop	af
	ret

;###############################################################################
; Internal BCD Function used to shift registers along a number of bytes so that
; commands can start from the MSB
;
; Input:	B = number of bytes to shift HL and DE along
;
; Routine from https://chibiakumas.com/z80/advanced.php
;###############################################################################

bcd_get_end:
	push	bc
	ld	c, b			; We want to add BC, but we need to
					; count the number of bytes minus one
	dec	c
	ld	b, 0
	add	hl, bc
	ex	hl, de			; We've done HL, but we also do DE

	add	hl, bc
	ex	hl, de
	pop	bc
	ret

;###############################################################################
; Internal BCD Function used to shift registers along a number of bytes so that
; commands can start from the MSB
;
; Input:	DE = location of BCD number array
; Input:	B = number of bytes in BCD number array
;
; Routine from https://chibiakumas.com/z80/advanced.php
;###############################################################################
bcd_show:
	call	bcd_get_end		; Need to process from the MSB not LSB

bcd_show_loop:
	ld	a, (de)
	and	%11110000		; Use the high nibble
	rrca
	rrca
	rrca
	rrca
	add	'0'			; Convert to a letter and print it
	call	TXT_OUTPUT
	ld	a, (de)
	dec	de
	and	%00001111		; Now the low nibble
	add	'0'
	call	TXT_OUTPUT
	djnz	bcd_show_loop		; Next byte
	ret

;###############################################################################
; Subtract two BCD numbers
;
; Input:	DE = number to subtract from
; Input:	HL = number to subtract
; Input:	B = number of bytes in BCD number array
;
; Routine from https://chibiakumas.com/z80/advanced.php
;###############################################################################

bcd_subtract:							
	or	a			; Clear carry flag

bcd_subtract_loop:
	ld	a, (de)
	sbc	(hl)			; Subtract HL from DE with carry
	daa				; Fix A using DAA
	ld	(de), a			; Store it

	inc	de
	inc	hl
	djnz	bcd_subtract_loop
	ret

;###############################################################################
; Add two BCD numbers
;
; Input:	DE = numbet to add to
; Input:	HL = number to add
; Input:	B = number of bytes in BCD number array
;
; Routine from https://chibiakumas.com/z80/advanced.php
;###############################################################################

bcd_add:
	or	a			; Clear carry flag

bcd_add_loop:
	ld	a, (de)
	adc	(hl)			; Add HL to DE with carry
	daa				; Fix A using DAA
	ld	(de), a			; Store it

	inc	de
	inc	hl
	djnz	bcd_add_loop
	ret

;###############################################################################
; Compare two BCD numbers
;
; Input:	DE = first number to compare
; Input:	HL = second number to compare
; Input:	B = number of bytes in BCD number array
; Output:	Z flag set if two numbers are equal
;
; Routine from https://chibiakumas.com/z80/advanced.php
;###############################################################################

bcd_compare:
	call	bcd_get_end		; Need to process from the MSB not LSB

bcd_compare_loop:			
	ld	a, (de)			; Start from MSB
	cp	(hl)
	ret	c			; Smaller
	ret	nz			; Greater
	dec	de			; Equal so move onto next byte
	dec	hl
	djnz	bcd_compare_loop
	or	a 			; Clear the carry flag
	ret

;###############################################################################
; Get the Absolute Difference (ABS) between two 8-bit numbers
;
; Input:	A = first number
; Input:	B = second number
; Output:	A = absolute difference
;###############################################################################

find_abs:
	sub	b
	or	a
	ret	p
	neg
	ret

;###############################################################################
; Check if two 8-bit numbers are different by a certain amount
;
; Input:	IX = first number
; Input:	IY = second number
; Input:	D = difference to check for
; Output:	A = #FF if correct difference, else #00
;###############################################################################

check_diff:				
	ld	a, (ix)			
	ld	b, a	
	ld	a, (iy)			
	sub	b
	cp	d			
	jr	z, check_diff_equal
	ld	a, #00
	ret

check_diff_equal:
	ld a,	#FF
	ret

;###############################################################################
; Beep!
;###############################################################################

beep:
	ld	a, 7
	call	TXT_OUTPUT
	ret

