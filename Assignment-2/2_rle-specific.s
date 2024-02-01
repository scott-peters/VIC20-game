; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1
; Creating a title page for our game
; Uses specific RLE for screen data 

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
						
			lda 	#<DATA						; Store pointer to data
			sta 	DATAPTR
			lda 	#>DATA
			sta 	DATAPTR+1

			ldy 	#$00						; Read fill 
			lda 	(DATAPTR),y
			tax
			ldy 	#$ff
.colrloop:		
			lda 	#$02
			sta 	COLRAM-1,y					; Since this is static and constant,
			sta 	COLRAM+#$ff-1,y				; there's no need to encode this
			txa
			sta 	SCRNMEM-1,y
			sta 	SCRNMEM+#$ff-1,y
			tax
			dey 
			bne 	.colrloop
				
			ldy 	#$00
.mainloop:
			iny									; Read address
			lda 	(DATAPTR),y
			beq 	.stop						; If 0, end of data
			sta 	ADDR+1
			iny
			lda 	(DATAPTR),y
			sta 	ADDR
			iny
.mainloop1:	
			lda 	(DATAPTR),y
			beq 	.mainloop					; If 0, then end of line
			tax
			iny
			sty 	TEMP						; Better than transferring to stack
			lda 	(DATAPTR),y
			ldy 	#$00
.loop:
			sta 	(ADDR),y					; set screen mem
			inc 	ADDR
			beq 	.updateHI
.retFrmUpd:	
			dex 
			bne 	.loop						; Loop till length=0
			ldy 	TEMP						; Retrieve Y
			iny									; No need to update DATAPTR high as data < 256
			jmp 	.mainloop1					; jump to mainloop. 
.stop:
			jmp 	.							; JAM
.updateHI:
			inc 	ADDR+1
			jmp 	.retFrmUpd					; get back to loop


DATA:
	incbin "screendata-rlespecific.bin"
DATAEND:
