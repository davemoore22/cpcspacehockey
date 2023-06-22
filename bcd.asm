; BCD Functions
;
; https://chibiakumas.com/z80/advanced.php

; Some of our commands need to start from the MSB, this routine will shift HL and DE along b bytes
_bcd_get_end:

	push bc
		ld c,b							; We want to add BC, but we need to number of bytes - 1
		dec c
		ld b,0
		add hl,bc
		ex hl,de						; We've done HL, but we also want to do DE

		add hl,bc
		ex hl,de
	pop bc
	ret

_bcd_show:

	call _bcd_get_end					; Need to process from the end of the array

_bcd_show_direct:

	ld a,(de)
	and %11110000						; Use the high nibble
	rrca
	rrca
	rrca
	rrca
	add '0'								; Convert to a letter and print it
	call #BB5A
	ld a,(de)	
	dec de
	and %00001111						; Now the low nibble
	add '0'
	call #BB5A
	djnz _bcd_show_direct				; Next byte
	ret

_bcd_subtract:							; Clear carry flag

	or a

_bcd_subtract_again:

	ld a,(de)
	sbc (hl)							; Subtract HL from DE with carry
	daa									; Fix A using DAA
	ld (de),a							; Store it

	inc de
	inc hl
	djnz _bcd_subtract_again
	ret

_bcd_add:

	or a								; Clear carry flag

_bcd_add_again:

	ld a,(de)
	adc (hl)							; Add HL to DE with carry
	daa									; Fix A using DAA
	ld (de),a							; Store it

	inc de
	inc hl
	djnz _bcd_add_again
	ret

_bcd_compare:

	call _bcd_get_end

_bcd_compare_direct:						; Start from MSB

	ld a,(de)
	cp (hl)
	ret c								; Smaller
	ret nz								; Greater
	dec de								; Equal so move onto next byte
	dec hl
	djnz _bcd_compare_direct
	or a 								; Clear the carry flag
	ret
