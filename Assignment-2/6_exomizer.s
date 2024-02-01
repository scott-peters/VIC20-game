; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1
; Uses Exomizer to decompress screen

			processor 6502

;;;;;;; EQUATES ;;;;;;;;
SCRNMEM  	EQU 	$1E00
SCRNMEM2	EQU 	$1F00
COLRAM 		EQU 	$9600
SCRNCOLR	EQU 	$900F

			SEG CODE
			ORG	$1001

BASICSTUB:
			dc.w	.BASICEND
			dc.w	5463
			dc.b	$9e, "4109", $00
.BASICEND
			dc.w	$00


START:
			lda     #$0a
            sta     SCRNCOLR 					; Screen color, Border color
			
			lda 	#$02						; Screen colour
			ldy 	#$ff
.colrloop:		
			sta 	COLRAM-1,y					; Since this is static and constant,
			sta 	COLRAM+#$ff-1,y				; there's no need to encode this
			dey
			bne 	.colrloop
			
			jsr 	exod_decrunch				; Call Exomizer decruncher
			jmp		.							; JAM


exod_get_crunched_byte:
        	lda		_byte_lo
        	bne 	_byte_skip_hi
        	dec 	_byte_hi
_byte_skip_hi:
        	dec 	_byte_lo
_byte_lo = * + 1
_byte_hi = * + 2
        	lda 	DATAEND               		; needs to be set correctly before
			rts
 
	include "exodecrunch.asm"

DATA:
	incbin "screendata-exomizer.bin"
DATAEND:


