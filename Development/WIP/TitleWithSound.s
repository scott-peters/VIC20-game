; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1
; Starting to put pieces together. Updated title graphics


			processor 6502

			SEG CODE
			ORG	$1001

BASICSTUB:
			
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

; Music Settings
JTIMER 	    EQU 	$A2
OSCLO 	    EQU 	$900A
OSCMID      EQU 	$900B
OSCHI   	EQU 	$900C
NOISE   	EQU 	$900D
VOL     	EQU 	$900E

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

PITPOSX		EQU		$10
PITPOSY		EQU		$11


START:		
			ldy 	#$00 		; Init counter
			lda     #$0a 
            sta     $900F 		; Screen color, Border color

; Clears the screen by setting 1e00-1fff to 0
ClrScreen:
			lda 	#32
			ldy 	#$ff
			ldx 	#02
.clrloop:	sta 	SCRNMEM-1,y			; 0x1e00 -- 0x1efe
			sta 	SCRNMEM+#$ff-1,y	; 0x1efe -- 0x1ffd
			txa
			sta 	SCRNCOLOR-1,y
			sta 	SCRNCOLOR+#$ff-1,y
			tax
			lda 	#32
			dey
			bne 	.clrloop

			lda 	#>GAMENAME
			sta 	$01
			lda 	#<GAMENAME
			sta 	$00

			lda 	#$1e
			sta 	$03
			lda 	#$30
			sta 	$02
			
loop:		ldy 	#$00
change:		lda 	($00),y
			beq 	ret
			sta 	($02),y
			iny
			jmp 	change

ret:		iny
			lda 	($00),y
			beq 	MUSIC
			iny 
			sta 	$05			; Hi address of location of next screen code
			lda 	($00),y	
			sta 	$04			; Lo address. Store temp.
			iny
			lda 	($00),y		; Get next color ram pointer
			sta 	$03			
			iny	
			lda 	($00),y
			sta 	$02
			lda 	$05
			sta 	$01
			lda 	$04
			sta 	$00	
            jmp     loop

MUSIC:
            lda     #$0f
			sta     VOL
			ldy     #00
			ldx     #02


.LOADNOTE	
			lda     RIFF,y
			beq     .CHECKCNT
			
			sta     OSCLO
			iny
			lda     RIFF,y
			sta     OSCMID 
			iny
			lda     RIFF,y
			sta     OSCHI
			iny
	
			lda     #00
			sta     JTIMER
.CHECKTIME	
			lda     JTIMER
			cmp     RIFF,y
			bne     .CHECKTIME

			lda     #00
			sta     OSCLO
			sta     OSCMID 
			sta     OSCHI
			sta     JTIMER
; The low sqr osc doesn't work for some reason without a delay
; Spent days figuring this out.
.CHECKJIFFY	
			lda     JTIMER
			beq     .CHECKJIFFY
			iny
			bne     .LOADNOTE
.CHECKCNT 
			dex
			txa
			beq     RETURN
			ldy     #00
			jmp     .LOADNOTE 

RETURN 		lda     #00
			sta     VOL
			jmp     GAMESTART   

GAMESTART:  
            jsr		$FFE4				; GETIN call address
			cmp		#$20				; Check if space is pressed, if not keep waiting
            bne     GAMESTART   
            lda     #$00                ; mute the music
            sta     VOL
            sta     NOISE  
			jsr 	InitScreen
			jsr 	ClrScreenGame
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

			lda 	#10				; Pass Coordinates
			sta 	PITPOSX
			lda 	#10
			sta 	PITPOSY
			jsr 	CalcPit

			;jsr		Keypress
			
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

ClrScreenGame:
			lda 	#00
			ldy 	#$ff
			
.clrloopGame:	
            sta 	SCRNMEM-1,y			; 0x1e00 -- 0x1efe
			sta 	SCRNMEM+#$ff-1,y	; 0x1efe -- 0x1ffd
			dey
			bne 	.clrloopGame

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

CalcPit:
			lda 	PITPOSX
			sta 	POSADDRLO 
			ldy  	PITPOSY				
			beq 	.DONE				
			jsr		.calcloop

			lda		#3
			jsr		Draw
			jsr		Keypress

StorePos:
			ldx		POSX
			stx 	OLDPOSX				; Storing the positions to erase later for movement
			ldx		POSY
			stx		OLDPOSY

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

			
done:		
			jmp		.


				  			;s   u   r   v   i   v   a   l       h  u   n  t
GAMENAME:	.byte $13,$15,$12,$16,$09,$16,$01,$0c,32,$08,$15,$e,$14,$00

			
GROUP:		;	  	 		g   r   o  u   p      0   9
			.byte #>(GROUP+4),#<(GROUP+4),$1e, $79, $07,$12,$f,$15,$10,32,$30,$39,$00

NAMES:		;      									s   h    a  n  k  a  r      g   a   n  e  s   h    ,
			.byte #>(NAMES+4), #<(NAMES+4), $1e, $a1, $13,$08,$01,$e,$b,$01,$12,32,$07,$01,$e,$5,$13,$08,$2c,$00
			;      a   b   h   i   n  a   v      s   a   x   e   n  a   ,
NAMES1:		.byte #>(NAMES1+4), #<(NAMES1+4), $1e, $cd, $01,$02,$08,$09,$e,$01,$16,32,$13,$01,$18,$05,$e,$01,$2c,$00
														;      s   c   o  t   t      p    e   t  e   r   s   ,
NAMES2:		.byte #>(NAMES2+4), #<(NAMES2+4), $1e, $fa, $13,$03,$f,$14,$14,32,$10,$05,$14,$05,$12,$13,$2c,$00
			;      n  a   z   n  i   n     s   h   i   s   h   i   r
NAMES3:		.byte #>(NAMES3+4), #<(NAMES3+4), $1f, $25, $e,$01,$1a,$e,$09,$e,32,$13,$08,$09,$13,$08,$09,$12,$00

BEGIN:		;      p   r   e  s    s     s    p   a   c   e      t  o      s   t   a   r   t
			.byte #>(BEGIN+4), #<(BEGIN+4), $1f, $b9, $10,$12,$05,$13,$13,32,$13,$10,$01,$03,$05,32,$14,$f,32,$13,$14,$01,$12,$14,$00

YEAR:
			.byte #>(YEAR+4), #<(YEAR+4), $1e, $01, $32, $30, $32, $32, $00

TIGER1:
			.byte #>(TIGER1+4), #<(TIGER1+4), $1e, $59, $69, $4b, $63, $4a, $5f, $00
TIGER2:
			.byte #>(TIGER2+4), #<(TIGER2+4), $1e, $6e, $55, 32, $57, 32, $57, 32, $49, $00
TIGER3:
			.byte #>(TIGER3+4), #<(TIGER3+4), $1e, $84, $42, 32, 32, 32, 32, 32, $42, $00
TIGER4:
			.byte #>(TIGER4+4), #<(TIGER4+4), $1e, $9a, $42, 32, 32, $51, 32, 32, $42, $00
TIGER5:
			.byte #>(TIGER5+4), #<(TIGER5+4), $1e, $b0, $42, $4a, 32, 32, 32, $4b, $42, $00
TIGER6:
			.byte #>(TIGER6+4), #<(TIGER6+4), $1e, $c6, $4a, $49, $16, 32, $16, $55, $4b, $00
TIGER7:
			.byte #>(TIGER7+4), #<(TIGER7+4), $1e, $de, $4e, 32, $4d, $00
TIGER8:
			.byte #>(TIGER8+4), #<(TIGER8+4), $1e, $f3, $4e, 32, 32, 32, $4d, $00
TIGER9:
			.byte #>(TIGER9+4), #<(TIGER9+4), $1f, $1f, $4d, $17, 32, $17, $4e, $00
TIGER10:
			.byte #>(TIGER10+4), #<(TIGER10+4), $1f, $35, $4e, 32, 32, 32, $4d, $00
TIGER11:
			.byte #>(TIGER11+4), #<(TIGER11+4), $1f, $4b, $4c, $41, $64, $41, $64, $7f, $00
TIGER12:
			.byte #>(TIGER12+4), #<(TIGER12+4), $1f, $67, $7f, $00
TIGER13:
			.byte #>(TIGER13+4), #<(TIGER13+4), $1f, $7d, $7f, $00


END:		.byte $00

; NOTE, NOTE, NOTE, DURATION
RIFF 		.byte 232,224,204,5,232,224,214,5,232,224,217,5,232,224,204,10,232,224,204,10,232,224,204,5,232,224,209,10,232,224,204,10,232,224,209,5,232,224,214,5,232,224,217,10
			.byte 229,221,204,5,229,221,214,5,229,221,217,5,229,221,204,10,229,221,204,10,229,221,204,5,229,221,209,10,229,221,204,10,229,221,209,5,229,221,214,5,229,221,217,10
			.byte 226,217,209,5,226,217,214,5,226,217,217,5,226,217,209,10,226,217,209,10,226,217,209,5,226,217,209,10,226,217,204,10,226,217,209,5,226,217,214,5,226,217,217,10
			.byte 229,221,204,5,229,221,214,5,229,221,217,5,229,221,204,10,229,221,204,10,229,221,204,5,224,214,209,10,224,214,204,10,229,221,214,5,229,221,217,5,229,221,224,10,0

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
