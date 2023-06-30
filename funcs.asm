;*******************************************************************************
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
;*******************************************************************************


;###############################################################################
;
; Print a string
;
; Input:	HL = address of string to print (terminated by 0)
; Corrupts:	A
;
;###############################################################################

print_string:
	ld	a, (hl)
	cp	0
	ret	z
	inc	hl
	call	TXT_OUTPUT
	jr	print_string

;###############################################################################
;
; Print a 3-digit decimal number
;
; Input:	A = 8-bit value to display
; Corrupts:	AF, BC
;
; Routine from https://tinyurl.com/mr39uep5
;
;###############################################################################

print_int:
	ld	b, 100			; Divisor to obtain 100's digit value
	call	print_int_digit		; Display digit
	ld	b, 10			; Divisor to obtain 10's digit value
	call	print_int_digit		; Display digit
	ld	b, 1			; Divisor to obtain 1's digit value

print_int_digit:
	ld	c, 0			; Zeroise result

print_int_dec_divide:
	sub	b			; Subtract divisor
	jr 	c, print_int_display	; If dividend < divisor, division ended
	inc	c			; Increment digit value
	jr	print_int_dec_divide

print_int_display:
	add	a, b			; Add divisor because dividend was
					; negative, leaving remainder
	push	af
	ld	a, c			; Get digit value
	add	a, '0'			; Convert value into ASCII character
	call	TXT_OUTPUT		; Display digit
	pop	af
	ret

;###############################################################################
;
; Internal BCD Function used to shift registers along a number of bytes so that
; commands can start from the MSB
;
; Input:	B = number of bytes to shift HL and DE along
; Corrupts:	DE, HL (Obviously)
;
; Routine from https://chibiakumas.com/z80/advanced.php
;
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
;
; Print BCD number
;
; Input:	DE = location of BCD number array
; Input:	B = number of bytes in BCD number array
; Corrupts:	AF, BC, DE, HL
;
; Routine from https://chibiakumas.com/z80/advanced.php
;
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
;
; BCD Subtraction
;
; Input:	DE = minuend
; Input:	HL = subtrahend
; Input:	B = number of bytes in BCD number array
; Output:	DE = minuend - subtrahend
; Corrupts:	AF, BC, DE, HL
;
; Routine from https://chibiakumas.com/z80/advanced.php
;
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
;
; BCD Addition
;
; Input:	DE = augend
; Input:	HL = addend
; Input:	B = number of bytes in BCD number array
; Output:	DE = augend + addend
; Corrupts:	AF, BC, DE, HL
;
; Routine from https://chibiakumas.com/z80/advanced.php
;
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
;
; BCD Comparison
;
; Input:	DE = First number to compare
; Input:	HL = Second number to compare
; Input:	B = number of bytes in BCD number array
; Output:	Z flag set if two numbers are equal
; Corrupts:	AF
;
; Routine from https://chibiakumas.com/z80/advanced.php
;
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
;
; Get the Absolute Difference (ABS(A-B)) between two 8-bit numbers
;
; Input:	A = first number
; Input:	B = second number
; Output:	A = absolute difference
; Corrupts:	AF, BC
;
;###############################################################################

find_abs:
	sub	b
	or	a
	ret	p
	neg
	ret

;###############################################################################
;
; Get the Absolute value of a Signed 8-bit Number (ABS)
;
; Input:	A = number
; Output:	A = ABS(A)
; Corrupts:	AF
;
;###############################################################################

find_abs_a:
	or a
	ret p
	neg
	ret

	ld a,	#FF
	ret

;###############################################################################
;
; Makes a Beep!
;
; Corrupts:	AF
;
;###############################################################################

beep:
	ld	a, 7
	call	TXT_OUTPUT
	ret

;###############################################################################
;
; Checks if either MSB or LSB in HL Register Pair is #FF
;
; Input:	HL = Bytes to Check
; Output:	A = #FF if either H or L is #FF, else A = #00
; Corrupts:	AF
;
;###############################################################################

check_hl_for_ff:
	ld	a, h
	cp	#FF
	jr	z, check_hl_for_ff_is
	ld	a, l
	cp	#FF
	jr	z, check_hl_for_ff_is

	ld	a, #00
	ret

check_hl_for_ff_is:
	ld	a, #FF
	ret

;###############################################################################
;
; Checks if both MSB or LSB in HL Register Pair is #FF
;
; Input:	HL = Bytes to Check
; Output:	A = #FF if both H or L is #FF, else A = #00
; Corrupts:	AF
;
;###############################################################################

check_hl_for_both_ff:
	ld	a, h
	cp	#FF
	jr	nz, check_hl_for_both_ff_not
	ld	a, l
	cp	#FF
	jr	nz, check_hl_for_both_ff_not

	ld	a, #FF
	ret

check_hl_for_both_ff_not:
	ld	a, #00
	ret
