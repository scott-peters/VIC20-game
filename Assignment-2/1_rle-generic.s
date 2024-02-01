; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1
; Creating a title page for our game
; Uses generic RLE 

			processor 6502

;;;;;;; EQUATES ;;;;;;;;
SCRNMEM  	EQU 	$1E00
SCRNMEM2	EQU 	$1F00
COLRAM 		EQU 	$9600
SCRNCOLR	EQU 	$900F

;;;;;;; ZP ;;;;;;;;;
DATAPTR   	EQU     $7
ADDR 		EQU 	$9
TEMP 		EQU 	$B

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
			lda 	#$ff
			sta 	ADDR
			lda 	#$1d
			sta 	ADDR+1
			
			lda 	#<DATA						; Store pointer to data
			sta 	DATAPTR
			lda 	#>DATA
			sta 	DATAPTR+1

			lda 	#$02						; Screen colour
			ldy 	#$ff
.colrloop:		
			sta 	COLRAM-1,y					; Since this is static and constant,
			sta 	COLRAM+#$ff-1,y				; there's no need to encode this
			dey
			bne 	.colrloop
			ldy 	#$00

.mainloop:
			lda 	(DATAPTR),y					; get length
			beq 	.stop						; If 0, stop
			tax
			iny
			sty 	TEMP						; Backup y. Since the X-indexed ins are useless
			lda 	(DATAPTR),y					; Get screen code
			ldy 	#$00						; zero out Y
.loop:
			sta 	(ADDR),y					; set screen mem
			inc 	ADDR						; inc low addr
			beq 	.updateHI					; update hi (to 1f) if 00
.retFrmUpd:	
			dex 
			bne 	.loop						; Loop till length=0
			ldy 	TEMP						; Retrieve Y
			iny	
			bne 	.mainloop					
			inc 	DATAPTR+1					; If 0-ff complete, then update hi
			jmp 	.mainloop					; jump to mainloop
.stop:
			jmp 	.							; JAM
.updateHI:
			inc 	ADDR+1
			jmp 	.retFrmUpd					; get back to loop

DATA:
	incbin "screendata-rle.bin"
DATAEND:
