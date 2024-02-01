; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1
; Moving our custom tiger sprite using keyboard input. 
; wasd for movement -- W- up , A- left, D- right, S- down

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
OLDPOSX		EQU		$E
OLDPOSY		EQU		$F


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
			lda 	#2 					; Draw 3rd sprite (1st is blank, 2nd is test, 3rd tiger)
			jsr 	Draw

			jsr		Keypress
			
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

; Calculating the sprite position of the old sprite before movement so we can erase it
RemoveOld:
			lda 	OLDPOSX	
			sta 	POSADDRLO 
			ldy  	OLDPOSY				
			beq 	.DONE				
			jsr		.calcloop

			lda		#0
			jsr		Draw
			jsr		Keypress

Keypress:
			jsr		$FFE4				; GETIN call address
			cmp		#0					; wait if nothing is pressed
			beq		Keypress
			cmp		#'A 				; If 'a' move left
			beq		Left
			cmp		#'D 				; If 'd' move right
			beq		Right
			cmp		#'W 				; If 'w' move up
			beq		Up
			cmp		#'S 				; If 's' move down
			beq		Down
			cmp		#0
			bne		Keypress

Left:
			; Need to store the POSX in OLDPOSX and set that to 0? then draw that again (bunch of 0's)
			; to clear the old character?? How is this done?
			ldx		POSX
			stx 	OLDPOSX				; Storing the positions to erase later for movement
			ldx		POSY
			stx		OLDPOSY

			ldx		POSX				; Decrement x position by 1 to move left 1 spot
			dex
			stx		POSX
			jsr		CalcSpritePos	
			;lda		#8				;This make it not draw, any idea why? trying to make it orange
			;sta		COLOR
			lda		#2
			jsr		Draw

			jsr		RemoveOld			; Remove the old drawing of the sprite to show movement

			jmp		Keypress


Right:
			ldx		POSX
			stx 	OLDPOSX				; Storing the positions to erase later for movement
			ldx		POSY
			stx		OLDPOSY

			ldx		POSX				; Increment x position by 1 to move right 1 spot
			inx
			stx		POSX
			jsr		CalcSpritePos
			lda		#2
			jsr		Draw

			jsr		RemoveOld			; Remove the old drawing of the sprite to show movement

			jmp		Keypress

Up:
			ldx		POSX
			stx 	OLDPOSX				; Storing the positions to erase later for movement
			ldx		POSY
			stx		OLDPOSY

			ldx		POSY				; Decrement y position by 1 to move up 1 spot
			dex
			stx		POSY
			jsr		CalcSpritePos
			lda		#2
			jsr		Draw

			jsr		RemoveOld			; Remove the old drawing of the sprite to show movement

			jmp		Keypress

Down:	
			ldx		POSX
			stx 	OLDPOSX				; Storing the positions to erase later for movement
			ldx		POSY
			stx		OLDPOSY

			ldx		POSY				; Increment y position by 1 to move down 1 spot
			inx
			stx		POSY
			jsr		CalcSpritePos
			lda		#2
			jsr		Draw

			jsr		RemoveOld			; Remove the old drawing of the sprite to show movement

			jmp		Keypress


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

TIGERCUB:
           	.byte	%00111100
			.byte	%00111100			; eyes in this one? not sure how to make it look good
			.byte	%00111100
			.byte	%10100101			; the two middle 1's should be white ears
			.byte	%10100101			
			.byte	%01111110
			.byte	%01110010
			.byte 	%01000110			
			.byte 	%01011110			
			.byte 	%01110010
			.byte  	%01001110
			.byte 	%01010010
			.byte 	%10111101
			.byte 	%10010001
			.byte 	%00010000
			.byte 	%00011000

PIT:
			.byte	%11111111
			.byte	%11000011
			.byte	%11000011
			.byte	%11000011
			.byte	%11000011
			.byte	%11000011
			.byte	%11000011
			.byte 	%11000011
			.byte 	%11000011
			.byte 	%11000011
			.byte 	%11000011
			.byte 	%11000011
			.byte 	%11000011
			.byte 	%11000011
			.byte 	%11000011
			.byte 	%11111111

NUMCHARS EQU 4							; Number of custom bitmaps
