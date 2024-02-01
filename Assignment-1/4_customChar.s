; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 Program 4
; Tests custom bitmaps/character set

	processor 6502
	
	SEG CODE
	ORG	$1001

BASICSTUB:
			; sys 4109 
			; The address will allways be 4109
			; as the length of the basic stub 
			; doesn't change
			dc.w	.BASICEND
			dc.w	5463
			dc.b	$9e, "4109", $00
.BASICEND
			dc.w	$00


;;;;;;;;;;; EQUATES ;;;;;;;;;;
CUSTCHRS	EQU 	$1C00
SCRNMEM 	EQU 	$1E00
MULTCOL 	EQU 	$08
NCOLUMNS 	EQU 	22
NROWS		EQU 	23
SCRNCOLOR	EQU 	$9600

; Screen Settings
SCRNCOL		EQU 	$9002
SCRNROW		EQU 	$9003
SCRCHM		EQU 	$9005
SCRCOL 		EQU 	$900F

;;;;;;;;;;; ZP ;;;;;;;;;;;;

POSADDR		EQU 	$7
POSADDRLO 	EQU 	$7
POSADDRHI	EQU 	$8

COLORADDR	EQU 	$9
COLORADDRLO EQU 	$9
COLORADDRHI	EQU 	$A
COLOR 		EQU 	$B

POSX 		EQU 	$C
POSY 		EQU 	$D


START:		
			jsr 	InitScreen
			jsr 	ClrScreen
			; jsr 	SetBackgroundColor	; TODO - Since we're using multicolor. Need to set separately
			lda 	#15					; Pass Coordinates
			sta 	POSX
			lda 	#10
			sta 	POSY
			jsr 	CalcSpritePos
			lda 	#5					; Green color
			sta 	COLOR
			lda 	#1 					; Draw 2nd sprite (1st is blank)
			jmp 	Draw
			
Draw:
			ldy 	#0
			sta 	(POSADDR),y			; Set bitmap
			lda 	COLOR				; Get Color
			sta 	(COLORADDR),y		; Set Color
			
			jmp 	.					; Don't bother doing anything now. Just jam. Or I guess
										; the equivalent of jam.

InitScreen:
			lda 	#%10010111			; Bit 0 sets 16x8, bits1-6 set no. of rows. Bit 7 = raster val
			sta 	SCRNROW
			lda		#$ff				; Custom char address = 1C000
			sta		SCRCHM 	
			lda 	#$08 				; Multicolor Screen
			sta 	SCRCOL
			
			jsr 	CopyChars			; Copy all chars to chr mem
			rts

; Clears the screen by setting 1e00-1fff to 0
ClrScreen:
			lda 	#00
			ldy 	#$ff
			
.clrloop:	sta 	SCRNMEM-1,y			; 0x1e00 -- 0x1efe
			sta 	SCRNMEM+#$ff-1,y	; 0x1efe -- 0x1ffd
			dey
			bne 	.clrloop
			; lda 	#00					; Set the remaining two bytes.
			; sta 	$1ffe				; Not doing this doesn't cause
			; sta 	$1fff				; any issues. Why?
			rts 								

; Copies all custom characters defined to 1C00
; NOTE: Since this is an 8-bit CPU, the max val is 255
; so max of NUMCHARS is 31 as 32*8 gives us 256. FOR 8x8 sprites
; For 16x8 sprites, max is 15
; But I guess it's enough for our game. Trees, cubs, tiger.
CopyChars:
			ldy 	#NUMCHARS*16+1		; 8x8 Sprites. Change to 16 for 16x8
.copyloop:	
			lda		BITMAPS-1,y
			sta 	CUSTCHRS-1,y
			dey
			bne		.copyloop
			rts

; Calculates address of the sprite given x,y position and the color address as well
; TODO: Multiplication by 16 is so much easier (just 4 shifts).
; Maybe have 16 columns instead?
; Avoids a loop and will only occupy 4 bytes as asl is implied
; Had 4 shifts and then add the remaining but it takes a byte or two more
; This is a bit slower but I guess it's alright - we get more space to play with
; Adress in POSADDR = Screen Base + X + Y*No. of columns
; Colour address in COLORADDR
CalcSpritePos:
			lda 	#>SCRNMEM			; Load screen base = 1e00
			sta 	POSADDRHI
			lda 	POSX	
			sta 	POSADDRLO 
			ldy  	POSY				; Need to multiply by num of columns
			beq 	.DONE				; If y-position is 0, return
.calcloop:	clc							; Addition loop
			lda 	POSADDRLO
			adc 	#NCOLUMNS				; No. of columns
			sta 	POSADDRLO
			lda 	#00
			adc 	POSADDRHI 
			sta 	POSADDRHI
			dey
			bne 	.calcloop
.DONE:		
			clc
			lda 	POSADDRHI
			adc 	#$78				; Add $78 to hi-base gets the color memory address
			sta 	COLORADDRHI
			lda 	POSADDRLO
			sta 	COLORADDRLO 		; Low 8-bits same.
			rts


; TODO: Set Background Color Routine


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

SMILE: 									; Smiley face from programmer's guide	
			.byte	%00111100
			.byte	%01000010
			.byte	%10100101
			.byte	%10000001
			.byte	%10100101
			.byte	%10011001
			.byte	%01000010
			.byte 	%00111100			; THe next 8 bytes are just random.
			.byte 	%11111111			; Just a test program
			.byte 	%10011110
			.byte  	%11111111
			.byte 	%11111111
			.byte 	%11111111
			.byte 	%11111111
			.byte 	%11111111
			.byte 	%11111111

; TIGERCUB:
;             .byte 	%
NUMCHARS EQU 2							; Number of custom bitmaps
