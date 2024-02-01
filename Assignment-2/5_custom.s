; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1
; Creating a title page for our game
; Uses custom scheme to display screen data

			processor 6502

;;;;;;; EQUATES ;;;;;;;;
SCRNMEM  	EQU 	$1E00
SCRNMEM2	EQU 	$1F00
COLRAM 		EQU 	$9600
SCRNCOLR	EQU 	$900F

;;;;;;; ZP ;;;;;;;;;
DATAPTR   	EQU     $7
ADDR 		EQU 	$9

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
						
			lda 	#<DATA						; Store pointer to data
			sta 	DATAPTR
			lda 	#>DATA
			sta 	DATAPTR+1

			ldy 	#$00						; Get Fill
			lda 	(DATAPTR),y
			tax									; Faster than pushing to stack
			ldy 	#$ff
.colrloop:		
			lda 	#$02
			sta 	COLRAM-1,y					; Since this is static and constant,
			sta 	COLRAM+#$ff-1,y				; there's no need to encode this
			txa									; Get fill from x
			sta 	SCRNMEM-1,y
			sta 	SCRNMEM+#$ff-1,y
			tax									; Save fill
			dey 
			bne 	.colrloop
				
			ldx 	#$00						; Y is 0 at this point
.mainloop:
			iny									; Get address/offset
			lda 	(DATAPTR),y
			beq 	.stop
			sta 	ADDR+1
			iny	
			lda 	(DATAPTR),y
			sta 	ADDR
			iny
.loop:
			lda 	(DATAPTR),y					; There is no need to update y as
			beq 	.mainloop					; the compressed data is only 114 bytes
			sta 	(ADDR,x)					; This was better than saving y 
			inc 	ADDR						; Update address
			beq 	.updateHi					; If low byte overflowed, inc high
.getback:	iny
			jmp 	.loop						; Read next char code
.updateHi:
			inc 	ADDR+1						; Increment high byte
			jmp	 	.getback

.stop:		jmp 	.							; JAM

DATA:
	incbin "customData.bin"
DATAEND:
