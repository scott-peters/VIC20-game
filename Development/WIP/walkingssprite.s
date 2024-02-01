; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82
; Walking sprite

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
OLDTOPPOSX	EQU		$E
OLDTOPPOSY	EQU		$F
OLDBOTPOSX	EQU		$10
OLDBOTPOSY	EQU		$11
COUNTER		EQU		$12

START:		
			jsr 	InitScreen
			jsr 	ClrScreen
			; ** I AM SORRY FOR THIS CODE
            ; I KNOW IT IS TOTALLY UNORGANIZED I WAS JUST TRYING RANDOM THINGS
            ; How do I make it not instantly change the image, is there something similar to sleep command or something?
			
			lda 	#15					; Pass Coordinates
			sta 	POSX
			lda 	#8
			sta 	POSY
			jsr 	CalcSpritePos
			lda 	#5					; Green color
			sta 	COLOR
			lda 	#1 					; Draw Tiger top half then draw tiger bottom half
			jsr 	Draw
            lda     POSX
            sta     OLDTOPPOSX
            lda     POSY
            sta     OLDTOPPOSY
			ldx		POSY
			inx
			stx 	POSY
			jsr 	CalcSpritePos
			lda 	#4
			jsr		Draw
            lda     POSX
            sta     OLDBOTPOSX
            lda     POSY
            sta     OLDBOTPOSY
			lda		#0
			sta		COUNTER
            jsr     Loop

			
			jsr		.
			
Draw:
			ldy 	#0
			sta 	(POSADDR),y			; Set bitmap
			lda 	COLOR				; Get Color
			sta 	(COLORADDR),y		; Set Color
			
			rts
			

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

;Implementing a short wait in order to show walking animation
Wait:   		
			dey
       		bne 	Wait
			dex
			bne		Wait
      		rts

DrawCycle1:
			ldy		#0
			ldx		#0
			jsr		Wait

			lda		#1
			sta		COUNTER

			lda     OLDTOPPOSX
            sta     POSX
            lda     OLDTOPPOSY
            sta     POSY
            jsr     CalcSpritePos
            lda     #3
            jsr     Draw

            lda     OLDBOTPOSX
            sta     POSX
            lda     OLDBOTPOSY
            sta     POSY
            jsr     CalcSpritePos
            lda     #2
            jsr     Draw

            jsr     Loop

DrawCycle2:
			ldy		#0
			ldx		#0
			jsr		Wait

			lda		#0
			sta		COUNTER

			lda     OLDTOPPOSX
            sta     POSX
            lda     OLDTOPPOSY
            sta     POSY
            jsr     CalcSpritePos
            lda     #1
            jsr     Draw

            lda     OLDBOTPOSX
            sta     POSX
            lda     OLDBOTPOSY
            sta     POSY
            jsr     CalcSpritePos
            lda     #4
            jsr     Draw

            jsr     Loop


Loop:
			lda		#0
            cmp		COUNTER
			beq		DrawCycle1		
			lda		#1
			cmp		COUNTER
			beq		DrawCycle2



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

TIGERCUBTOP1: 										
			.byte	%00011000
			.byte	%00111100
			.byte	%00111100
			.byte	%01111110
			.byte	%01011010
			.byte	%01111110
			.byte	%00111100
			.byte 	%10100101			
			.byte 	%10101101			
			.byte 	%11100111
			.byte  	%11111111
			.byte 	%00111100
			.byte 	%00110100
			.byte 	%00101100
			.byte 	%00101100
			.byte 	%00110100

TIGERCUBBOT1:
           	.byte	%00111100
			.byte	%00100100			
			.byte	%00111100
			.byte	%00101100			
			.byte	%00100100			
			.byte	%00110100
			.byte	%00111100
			.byte 	%11111111			
			.byte 	%11111111			
			.byte 	%10010001
			.byte  	%10010001
			.byte 	%00100000
			.byte 	%00100100
			.byte 	%00111100
			.byte 	%00000000
			.byte 	%00000000

TIGERCUBTOP2: 										
			.byte	%00011000
			.byte	%00111100
			.byte	%00111100
			.byte	%01111110
			.byte	%01011010
			.byte	%01111110
			.byte	%00111100
			.byte 	%00100100			
			.byte 	%00101100			
			.byte 	%11100111
			.byte  	%11111111
			.byte 	%10111101
			.byte 	%10110101
			.byte 	%00101100
			.byte 	%00101100
			.byte 	%00110100

TIGERCUBBOT2:
           	.byte	%00111100
			.byte	%00100100			
			.byte	%00111100
			.byte	%00101100			
			.byte	%00100100			
			.byte	%10110101
			.byte	%10111101
			.byte 	%11111111			
			.byte 	%11111111			
			.byte 	%00010000
			.byte  	%00010000
			.byte 	%00100000
			.byte 	%00100100
			.byte 	%00111100
			.byte 	%00000000
			.byte 	%00000000

NUMCHARS EQU 5							; Number of custom bitmaps
