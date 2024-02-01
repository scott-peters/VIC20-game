	processor 6502


	SEG.U EQUATES

;;;;;; EQUATES ;;;;;;;
SCRNHOC 	EQU		$9000	
SCRNVEC		EQU		$9001	
SCRNNCOL	EQU		$9002	
SCRNNROW	EQU		$9003	
SCRNRAST	EQU		$9004	
SCRNCHRM	EQU		$9005	
SCRNCOLR	EQU		$900F	
SCRNMEM 	EQU 	$1E00
CHRMEM 		EQU 	$1C00
COLORRAM	EQU 	$9600
;;;;;; CONSTANTS ;;;;;

COUNTER 	EQU 	$E

NCOLUMNS 	EQU 	#22 ;COLUMNS
NROWS 		EQU 	#11 ; ROWS 

DELTAPIX	EQU 	$ff 			; Controls timing 
;;;;;;; ZP ;;;;;;;;


	SEG CODE
	ORG	$1001



BASICSTUB:
			dc.w	.BASICEND
			dc.w	5463
			dc.b	$9e, "4109", $00
.BASICEND
			dc.w	$00


START:
			jsr 	InitScreen
			lda 	#$ff
			sta 	DELTAPIX
			lda 	#00
			sta 	COUNTER

			sei 					; Disable Interrupts
			
loop:		ldy 	#$63			; Wait for raster
checksl:	cpy 	SCRNRAST 		
			bne 	checksl	

			lda 	DELTAPIX 		; Divide by 2 each loop
			lsr
			sta 	DELTAPIX

			beq 	scroool			; If N is set, scroll 
			jmp 	loop			; If not, wait for the next 200 line scan


scroool:
			ldx 	#0
; Only 11 rows so no need to shift entire screen mem
halfloop:
			lda 	$1e16,x
			sta 	$1e00,x
			lda 	$9616,x			; Shift colour as well
			sta 	$9600,x		
			inx
			bne 	halfloop

; Small counter which draws whenever it reaches 0
drawSprite:
			ldx 	COUNTER
			beq 	draw
			dex
			stx 	COUNTER
			jmp 	loop

draw:		lda 	#1	
			sta 	$1efc,x
			lda 	#$5
			sta 	$96fc,x
			lda 	#$40
			sta 	COUNTER
			jmp 	loop				


InitScreen:
			lda 	#05			; Set Horizontal Positioning
			sta 	SCRNHOC
			lda 	#25			; Set Vertical Position
			sta 	SCRNVEC
			lda 	#$17			; no. of rows
			sta 	SCRNNROW 
			lda 	#$ff			; Character memory (1c00)
			sta 	SCRNCHRM 
			lda 	#$0b			; Multicolor mode
			sta 	SCRNCOLR
			jsr		ClrScreen
			rts

; Clears the screen by setting 1e00-1fff to 0
ClrScreen:
			lda 	#0
			ldy 	#$ff

.clrloop:	sta 	SCRNMEM-1,y			; 0x1e00 -- 0x1efe
			sta 	SCRNMEM+#$ff-1,y	; 0x1efe -- 0x1ffd
			dey
			sta 	$1ffe
			sta 	$1fff
			bne 	.clrloop
			rts


	SEG GFX 
	ORG $1C00 							; Don't know why I didn't think of this earlier.
BITMAPS:
BLANK:
			.byte	$00
			.byte	$00
			.byte	$00
			.byte	$00
			.byte	$00
			.byte	$00
			.byte	$00
			.byte 	$00
			.byte 	$00
			.byte 	$00
			.byte 	$00
			.byte 	$00
			.byte 	$00
			.byte 	$00
			.byte 	$00
			.byte 	$00

UGLYTREETOP:
			.byte %00011000
    	    .byte %00100100
    	    .byte %01000010
    	    .byte %10000001
    	    .byte %01011011
    	    .byte %01101101
    	    .byte %10000110
    	    .byte %10000001
    	    .byte %01100010
    	    .byte %10010110
    	    .byte %10001001
    	    .byte %01000010
    	    .byte %00110100
    	    .byte %00011000
    	    .byte %00111100
    	    .byte %10000001


NUMCHARS EQU 4

