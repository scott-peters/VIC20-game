; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1
; Creating a title page for our game
; Uses ZX02 to decompress screen

			processor 6502

;;;;;;; EQUATES ;;;;;;;;
SCRNMEM  	EQU 	$1E00
SCRNMEM2	EQU 	$1F00
COLRAM 		EQU 	$9600
SCRNCOLR	EQU 	$900F

;;; Values for decompressor ;;;
SRCDATA		EQU 	zx0_ini_block+2

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
			
			lda 	#<DATA						; Only data changes. The dest. does not
			sta		SRCDATA  					; But can be changed if needed.
			lda 	#>DATA
			sta 	SRCDATA+1
			jsr 	full_decomp					; Call ZX02 decompressor
			jmp		.							; JAM

	include "zx02_decomp.asm"

DATA:
	incbin "screendata-zx02.bin"
DATAEND:
