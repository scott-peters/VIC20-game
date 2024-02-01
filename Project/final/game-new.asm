;; CPSC 5999.82 - Retrogames Fall 2022
;; Group 9
;; Shankar Ganesh, Scott Peters, Naznin Shishir, Abhinav Saxena

;; SURVIVAL HUNT
;; Uses JOYSTICK to move left, right and activate powerup (fire)
;; A = ff gives full powerup. Press Fire to activate powerup


		processor 6502

SCRNMEM 		EQU 	$1E00
SCRNRAST		EQU 	$9004
SCRNHPOS		EQU 	$9000
SCRNVPOS		EQU 	$9001
SCRNNCOL		EQU 	$9002
SCRNNROW		EQU 	$9003
SCRNCHLOC		EQU 	$9005
CHRMEM 			EQU 	$1C00
COLOURRAM		EQU 	$9600
SCRNCOLR		EQU 	$900F
AUXCOLR 		EQU 	$900E
OSCVOL 			EQU 	$900E
OSC1FREQ		EQU 	$900A
OSC2FREQ		EQU 	$900B
OSC3FREQ		EQU 	$900C
NOISEFREQ		EQU 	$900D
JOYPORTA		EQU 	$9111
JOYPORTB 		EQU 	$9120
DDRB 			EQU 	$9122

TIGERPOSX		EQU 	$7
TIGERPOSY		EQU 	$1edc
TIGERCOLRAM		EQU 	$96dc

LIVES			EQU 	$9
POWERUP 		EQU 	$A
FOODACC			EQU 	$B
LEVEL 			EQU 	$C
SPEED 			EQU 	$14
DELTASPEED		EQU 	$15

NCOLUMNS		EQU 	22
NROWS			EQU 	13

SCREENLIVES		EQU 	$1f08
SCREENLIVESCLR	EQU 	$9708

SCREENPOWER		EQU 	$1f18
SCREENPOWERCOLR	EQU 	$9718

SCREENRIVER 	EQU 	$1f0b
SCREENRIVERCLR	EQU 	$970b

MAXPOWERUPBAR 	EQU 	6
TEMP 			EQU 	$18

MAX_LEVEL       EQU 	#48

CURRENTROWBLOCK	EQU 	$3

VISIBLEROWS 	EQU 	12

BRIDGE 			EQU 	$20

DELAY 			EQU 	$30

CURRENTROWCNT	EQU 	$31
;; TODO: Organize all the vars properly
;;;;;; ZP ;;;;;;;;
;;;;;; CONSTANTS ;;;;;;



;;;;;; COLOURS ;;;;;;

BLACK			EQU 	#0
WHITE			EQU 	#1
RED				EQU 	#2
YELLOW			EQU 	#7
GREEN			EQU 	#5
BLUE			EQU 	#6
CYAN 			EQU 	#3
PURPLE			EQU 	#4
ORANGE			EQU 	#8
LIGHTBLUE 		EQU 	#$0e

SCREENCOLOUR	EQU 	#$7f


RANDOMLO		EQU 	$20
RANDOMHI		EQU 	$21

JIFFY 			EQU 	$A2

CURRENTBLOCK 	EQU 	$1
CURRENTBLOCKLO	EQU		$1
CURRENTBLOCKHI	EQU		$2

ZX02SRCDATA		EQU 	zx0_ini_block+2

	SEG CODE
	ORG $1001


BASICSTUB:
			dc.w 	.BASICEND
			dc.w 	5463
			dc.b 	$9e, "4109", $00
.BASICEND:
			dc.w 	$00


;; Rework/fix
;; TODO -- Data list and loop initialization of vars
START:
			cld 										; Clear Decimal
			lda 	#%01111111							; Setup Joysticks
			sta 	DDRB
			lda 	#$ff
			sta 	JOYPORTB

			lda 	#<TITLESCREEN						; ZX02 compression data source init.
			sta		ZX02SRCDATA 
			lda 	#>TITLESCREEN
			sta 	ZX02SRCDATA+1

			jsr 	showScreen							; Decode screen to screen memory
			sei											; Disable Interrupts
			jsr 	initScreen							; Initialize Screen
			lda 	#$20								; BUG. Maybe because of raster? If yes, will moving to interrupts fix it?
			sta 	SPEED								; Speed of scrolling
			jsr 	copyChars							; Copy custom chars
			lda 	#>BLOCKSTART						; Starting Block/map
			sta 	CURRENTBLOCKHI
			lda 	#<BLOCKSTART
			sta 	CURRENTBLOCKLO
			jsr 	drawBlock							; Draw first row
			lda 	#11									; Default tiger position
			sta 	TIGERPOSX
			jsr 	drawTiger
			lda 	#3
			sta 	LIVES								; 3 Lives
			lda 	#$A9
			sta 	RANDOMHI
			lda 	#$30
			sta 	RANDOMLO							; 16-bit LFSR from Dragonfire
			lda 	#$00
			sta 	POWERUP								; full powerup at start
			jsr 	drawHealthPower						; Draw both lives and powerup bar
			lda 	#$01
			sta 	LEVEL
			jsr 	drawRiver
mainloop:	
			ldx 	#$72								; Pheww.. This took soooo long. Might change it to interrupts
.wait:
			cpx 	SCRNRAST
			bne 	.wait

			lda 	LIVES
			beq 	gameOver

			jsr 	clearTiger							; Clear the tiger before scrolling

			lda 	SPEED								; Speed is only > 20 when powerup is active
			cmp 	#$20
			beq 	.nodec

			lda 	POWERUP								; If powerup is active, decrement powerup by 1
			sec
			sbc 	#$01
			sta 	POWERUP
			bcs 	.nodec

			lda 	#$00
			sta 	POWERUP								; Go back to original speed
			lda 	#$20
			sta 	SPEED

.nodec:		
			clc
			lda 	DELAY
			adc		$01
			sta 	DELAY
			bcc 	.scrl
			jsr 	checkJoy							; CHeck joystick input. Delay it for a while

.scrl		lda 	DELTASPEED							; Check if needed to scroll
			clc	
			adc 	SPEED
			sta 	DELTASPEED
			bcs 	scrollChar							; Scroll entire char mem by 1 char
			
			jsr 	moveScreen							; Move the screen by 2 px
contMain:	
			jmp 	mainloop
			

;; GAME OVER SCREEN.
gameOver SUBROUTINE
			cli											; Enable INterrupts
			lda 	#240								; Restore Screen settings
			sta 	SCRNCHLOC
			lda 	#46
			sta 	SCRNNROW
			lda 	#25
			sta 	SCRNVPOS	
			
			lda 	#<GAMEOVERSCRN			
			sta		ZX02SRCDATA
			lda 	#>GAMEOVERSCRN
			sta 	ZX02SRCDATA+1
			jsr 	showScreen
						
			jmp 	START								; If SPACE is pressed, start new game



;;; Scroll the entire char mem by one char (8x16) (16px)
scrollChar SUBROUTINE
			ldy 	#$58								; Scroll lower half
.loop1:		
			lda 	$1e9a-1,y
			sta 	$1eb0-1,y
			lda 	$969a-1,y 
			sta 	$96b0-1,y
			dey
			bne 	.loop1
			
			jsr 	moveScreen

			ldy 	#$9a								; Scroll upper half
.loop2:
			lda 	SCRNMEM-1,y 
			sta 	$1e16-1,y 
			lda 	COLOURRAM-1,y 
			sta 	$9616-1,y 
			dey
			bne 	.loop2

			ldy 	#NCOLUMNS							; Empty the top row
			lda 	#NBLANK
.loop3:
			sta 	SCRNMEM-1,y
			dey
			bne 	.loop3


			lda     SCREENRIVER
			sta 	TEMP
			lda     SCREENRIVER+NCOLUMNS
			pha
			ldy     #0
.charscrollloop:
			lda     SCREENRIVER+1,y
			sta     SCREENRIVER,y
			lda     SCREENRIVER+1+#NCOLUMNS,y
			sta     SCREENRIVER+#NCOLUMNS,y
			iny
			cpy     #11
			bne     .charscrollloop
			pla
			sta     SCREENRIVER+#NCOLUMNS,y
			lda 	TEMP
			sta 	SCREENRIVER,y

			jsr 	drawBlock							; Draw row of block
			;jsr 	drawRow								; Draw a row of the current tilemap

; 			ldy 	#$f2								; Scroll bullet twice as fast
; .loop4:	
; 			lda 	$1e00-1,y
; 			cmp 	#NBULLET
; 			bne 	.next
; 			sta 	$1e00-1+#NCOLUMNS,y
; 			lda 	#NBLANK
; 			sta 	$1e00-1,y
; .next:
; 			dey
; 			bne 	.loop4

			jmp 	contMain							; Jump to mainloop

			

;; DELTASPEED increments by speed and according to it, we calculate the 
;; amount to shift. We first divide the value by 
;; 16 (16 px height) (4 lsr's) which clips the value to 0-15
;; and then add the min amount * 2 (original pos of screen)
;; It's basically just linear interpolation
;; Project/Map values from 0-f to screen original pos-+8 (since screen can only be moved with 8px)
;; Screen can be moved only by 2px which is why we divide the value by 2 at the end

;; My dad helped me a bit with this part.
;; Just discussion (he doesn't know 6502 or the platform)
moveScreen SUBROUTINE
			lda 	DELTASPEED							; Calculate amount to shift the screen
			lsr
			lsr
			lsr
			lsr
			tax											; Save for later use to shift chars
			clc
			adc 	#$04
			lsr
			sta 	$9001
			

			lda 	#$00
			ldy 	#32									; Several ways to do this. 
.clearChr:												; After trying out various methods, 
			sta 	CHRMEM+#NTIGERSHIFT*16-1,y			; I think clearing everything and re-drawing is the best
			sta 	CHRMEM+#NLIFESHIFT*16-1,y
			sta 	CHRMEM+#NBARSHIFT*16-1,y
			sta 	CHRMEM+#NRIVERSHIFT1*16-1,y
			sta 	CHRMEM+#NRIVERSHIFT2*16-1,y
			sta 	CHRMEM+#NRIVERSHIFT3*16-1,y
			dey
			bne 	.clearChr

			txa
			eor 	#$0f								; Get the difference
			tax											; We need to shift the char starting at (0xf - shift) 

			ldy 	#00									; Copy the original char again to charmem
.copychr:												; shifting the appropriate amount
			lda 	TIGER,y
			sta 	CHRMEM+#NTIGERSHIFT*16,x
			lda 	CUB,y
			sta 	CHRMEM+#NLIFESHIFT*16,x
			lda 	#$fe
			sta 	CHRMEM+#NBARSHIFT*16,x
			lda 	RIVERCONVEXA1,y 
			sta 	CHRMEM+#NRIVERSHIFT1*16,x 
			lda 	RIVERCONVEXB2,y 
			sta 	CHRMEM+#NRIVERSHIFT2*16,x 
			lda 	RIVERSTRAIGHT3,y 
			sta 	CHRMEM+#NRIVERSHIFT3*16,x 
			inx
			iny
			cpy 	#16
			bne 	.copychr

			jsr 	drawTiger							; Draw the tiger & powerup bar


			rts
		

;; This is used as a bridge to get back to mainloop
;; as it is out of bounds for branching (or used to be)
bridge:		jmp 	mainloop

;; Check user input using joysticks
checkJoy SUBROUTINE
			lda 	DELTASPEED
			lsr
			lsr
			lsr
			lsr
			bcs 	.ret								; Try to slow down the joystick?

			lda 	JOYPORTA							; Get Joystick A Port
			and 	#%00010000							; Check if left
			bne 	.checkRight
			lda 	TIGERPOSX							; Check bounds
			beq 	.ret
			ldx 	TIGERPOSX							; Check if trees are on the side
			dex
			jsr 	checkTreeSides
			beq 	.ret
			dec 	TIGERPOSX
.checkRight:
			lda 	JOYPORTB							; Check Joyport B
			and 	#%10000000							; Check if right
			bne 	.checkPowerup
			lda 	TIGERPOSX
			cmp 	#NCOLUMNS-1							; Check bounds
			beq 	.ret
			ldx 	TIGERPOSX
			inx
			jsr 	checkTreeSides						; Check if trees are on the side
			beq 	.ret
			inc 	TIGERPOSX
.checkPowerup:
			lda 	JOYPORTA							; Check if FIRE is pressed for powerup
			and 	#%00100000
			bne 	.ret
			lda 	POWERUP
			beq 	.ret
			lda 	#$40								; Double the speed
			sta 	SPEED
.ret:		rts		


;; Checks for bounds. Realistically, a tiger CAN move
;; through trees, etc. But this is a game.
;; And in this game, the tiger cannot move through trees.
;; Takes one argument in the X register,
;; the X position to check
;; Sets Zero flag!!!
;; Z = 0 means no collision
checkTreeSides SUBROUTINE
			lda		TIGERPOSY,x
			cmp 	#NTREE
			rts


checkCollision SUBROUTINE
			beq 	.ret								; If 0, return (space)
			sty 	TEMP								; Save Y
			cmp 	#NOBSTACLES							; Obstacles >= 9
			bcs 	.rmLife

.food:
			cmp 	#NFOOD
			bne 	.rmLife
			lda 	POWERUP
			cmp 	#$ff
			beq 	.ret
			clc
			adc 	#$0f								; If food, then add to powerup
			sta 	POWERUP
			txa
			rts
.rmLife:
			dec 	LIVES
			jsr 	drawHealthPower						; Update health and power bar
			ldy 	TEMP
.ret:		txa
			rts


;;;;;;;;; INIT SCREEN ;;;;;;;;
initScreen SUBROUTINE
			ldy 	#$06
.loop:
			lda 	.screenSettings-1,y					; Set screen settings in a loop
			sta 	SCRNHPOS-1,y
			dey
			bne 	.loop 

			lda 	#SCREENCOLOUR
			sta 	SCRNCOLR
			lda 	#%00010000							; Set auxiliary colour for river
			sta 	OSCVOL
			ldy 	#$ff
.clrloop:
			lda 	#$00
			sta 	SCRNMEM-1,y							; Clear screen memory
			sta 	SCRNMEM+#$ff-1,y
			dey
			bne 	.clrloop
			rts

.screenSettings:
			.byte 	$04, $02, $96, $1d, $0, $ff	



;;;;;;;;;; ZX02 Compressed SCREEN ;;;;;;;;
showScreen SUBROUTINE									; Show a ZX02 decompressed screen
			lda 	#$08
			sta 	SCRNCOLR
			lda 	#$02
			ldy 	#$00
.loop:
			sta 	COLOURRAM,y
			sta 	COLOURRAM+#$ff,y
			iny
			bne 	.loop

			jsr 	full_decomp
			jsr 	MEGITSUNE							; Play megitsune music
.wait:		
			lda 	JOYPORTA							; Wait for start (fire)
			and 	#%00100000
			bne 	.wait
			rts


;; Draw the tiger
drawTiger SUBROUTINE
			ldx 	#NTIGERSHIFT						; Check collision and draw tiger
			ldy 	TIGERPOSX
			lda 	TIGERPOSY,y
			jsr 	checkCollision
			sta 	TIGERPOSY,y
			ldx 	#NTIGER
			lda 	TIGERPOSY+#NCOLUMNS,y
			jsr 	checkCollision
			sta 	TIGERPOSY+#NCOLUMNS,y

			lda 	#BLACK
			sta 	TIGERCOLRAM,y
			sta 	TIGERCOLRAM+#NCOLUMNS,y

.cont:		lda 	POWERUP								; Calculate number of bars to draw for powerup
			lsr
			lsr
			lsr
			lsr
			lsr
			sec
			sbc 	#$01
			bmi 	.ret
			tay
			beq 	.ret
			
.barloop:	
			lda 	#NBARSHIFT							; Draw bars
			sta 	SCREENPOWER-1,y
			lda 	#NBAR
			sta 	SCREENPOWER-1+#NCOLUMNS,y
			lda 	#RED
			sta 	SCREENPOWERCOLR-1,y
			sta 	SCREENPOWERCOLR-1+#NCOLUMNS,y
			dey
			bne 	.barloop
.ret:		rts


drawRiver SUBROUTINE
			lda 	#%00010000
    		sta     OSCVOL
			ldx 	#4
			ldy 	#$0

.loop:
			lda 	#NRIVERSHIFT1
			sta 	SCREENRIVER,y
			lda 	#NRIVERCONVEXA1
			sta 	SCREENRIVER+#NCOLUMNS,y 
			iny
			lda 	#NRIVERSHIFT2
			sta 	SCREENRIVER,y
			lda 	#NRIVERCONVEXB2
			sta 	SCREENRIVER+#NCOLUMNS,y 
			iny
			lda 	#NRIVERSHIFT3
			sta 	SCREENRIVER,y
			lda 	#NRIVERSTRAIGHT3
			sta 	SCREENRIVER+#NCOLUMNS,y 
			
			dex
			bne 	.loop

			ldy 	#12
			lda 	#BLUE
.colrloop:
			sta 	SCREENRIVERCLR-1,y
			sta 	SCREENRIVERCLR-1+#NCOLUMNS,y
			dey
			rts
			

;; Clear the tiger and powerup bars
clearTiger SUBROUTINE
			lda 	#NBLANK
			ldy 	TIGERPOSX
			sta 	TIGERPOSY,y
			sta 	TIGERPOSY+#NCOLUMNS,y

			ldy 	#MAXPOWERUPBAR
.barloop:	
			sta 	SCREENPOWER-1,y
			sta 	SCREENPOWER-1+#NCOLUMNS,y
			dey
			bne 	.barloop
			rts


; Copy characters to 
copyChars SUBROUTINE
			ldy 	#NBITMAPS*16+1
.copyloop:	
			lda		BITMAPS-1,y
			sta 	CHRMEM-1,y
			dey
			bne		.copyloop

			ldy 	#16*3
.copyloop2:
			lda 	BULLETUP-1,y 
			sta 	CHRMEM+16*#NBITMAPS-1,y 
			dey
			bne 	.copyloop2
			rts


;;;;;;;;;;;;;; AUDIO ;;;;;;;;;;;;;;;
; Gunshot Sound
SHOOTSOUND SUBROUTINE 
			lda 	#$0f
			sta 	OSCVOL
			ldy 	#$ff
.shootloop:
			sty 	OSC3FREQ
			sty 	NOISEFREQ
			ldx 	#$ff
.shootwaste:
			dex
			bne 	.shootwaste
			stx 	OSC3FREQ
			stx 	NOISEFREQ
			inx
			dey
			cpy 	#128
			bne 	.shootloop
			rts


; Cycle through blocks
; Starting from BLOCKSTART TO BLOCKSEND
drawBlock SUBROUTINE
			jsr 	drawRow

			lda 	CURRENTBLOCKLO
			cmp 	#<BLOCKSEND
			bne 	.cont
			lda 	CURRENTBLOCKHI
			cmp 	#>BLOCKSEND
			bne 	.cont
			lda 	#<BLOCKSTART
			sta 	CURRENTBLOCKLO
			lda 	#>BLOCKSTART
			sta 	CURRENTBLOCKHI
.cont:
			clc
			lda 	CURRENTBLOCKLO
			adc 	#$03
			sta 	CURRENTBLOCKLO
			lda 	CURRENTBLOCKHI
			adc 	#$00
			sta 	CURRENTBLOCKHI

			rts



;; Draw a row of trees from block
;; SUPER SUPER Ineffecient but it works and I ain't touching this
;; It's 8, 8, 6 bytes so kinda weird to loop
;; I did try it but the screen was messed up for some reason. eh..
drawRow SUBROUTINE
			ldy 	#$00				
			ldx 	#$00

			lda 	#8									; Draw first 8 bytes
			sta 	TEMP
			lda 	(CURRENTBLOCK),y
			clc
.loop:
			rol
			pha
			bcc 	.next

			lda 	#NTREE
			sta 	SCRNMEM,x
			lda 	#GREEN
			sta 	COLOURRAM,x
			
.next:		pla
			inx
			dec 	TEMP
			bne 	.loop

			lda 	#8									; Draw seond 8 bytes
			sta 	TEMP
			iny
			lda 	(CURRENTBLOCK),y
			clc
.loop1:
			rol
			pha
			bcc 	.next1

			lda 	#NTREE
			sta 	SCRNMEM,x
			lda 	#GREEN
			sta 	COLOURRAM,x
			
.next1:		pla
			inx
			dec 	TEMP
			bne 	.loop1

			lda 	#6									; Draw 6 bytes as max is 22 columns
			sta 	TEMP
			iny
			lda 	(CURRENTBLOCK),y
			clc
.loop2:
			rol
			pha
			bcc 	.next2

			lda 	#NTREE
			sta 	SCRNMEM,x
			lda 	#GREEN
			sta 	COLOURRAM,y
			
.next2:		pla
			inx
			dec 	TEMP
			bne 	.loop2
			
.ret:
			rts
		

; Draw lives
drawHealthPower SUBROUTINE								
			ldy 	#3
.loopcl:
			lda 	#NBLANK
			sta 	SCREENLIVES-1,y
			sta 	SCREENLIVES+NCOLUMNS-1,y
			dey
			bne 	.loopcl

			ldy 	LIVES
			beq 	.ret
.loop:
			lda 	#NLIFESHIFT
			sta 	SCREENLIVES-1,y

			lda 	#NLIFE
			sta 	SCREENLIVES+#NCOLUMNS-1,y 

			lda 	#BLACK
			sta 	SCREENLIVESCLR-1,y 
			sta 	SCREENLIVESCLR+#NCOLUMNS-1,y 
			dey
			bne 	.loop

.ret:		rts

; megistune (from assignment 1)
MEGITSUNE SUBROUTINE
			lda #$0f
			sta OSCVOL
			ldy #00
			ldx #02

.LOADNOTE	
			lda 	RIFF,y
			beq 	.CHECKCNT
			
			sta 	OSC1FREQ
			iny
			lda 	RIFF,y
			sta 	OSC2FREQ 
			iny
			lda 	RIFF,y
			sta 	OSC3FREQ
			iny
	
			lda 	#00
			sta 	JIFFY
.CHECKTIME	
			lda 	JIFFY
			cmp 	RIFF,y
			bne 	.CHECKTIME

			lda 	#00
			sta 	OSC1FREQ
			sta 	OSC2FREQ 
			sta 	OSC3FREQ
			sta 	JIFFY
; The low sqr osc doesn't work for some reason without a delay
; Spent days figuring this out.
.CHECKJIFFY	
			lda 	JIFFY
			beq 	.CHECKJIFFY
			iny	
			bne 	.LOADNOTE
.CHECKCNT 	
			dex	
			txa	
			beq 	.RETURN
			ldy 	#00
			jmp 	.LOADNOTE 
	
.RETURN 	lda 	#00
			sta 	OSCVOL
			rts


;;;; DRAGONFIRE!!!
;;;; 16-bit LFSR for PCG
genRandom SUBROUTINE 										; 16-bit rnadom LFSR
			lda 	RANDOMLO
			ror
			ror
			ror
			eor 	RANDOMHI
			asl
			asl
			rol 	RANDOMLO
			rol 	RANDOMHI
			lda 	RANDOMLO
			rts
			
NBITMAPS=15
BITMAPS:

NBLANK=0
BLANK:
			ds.b 	16,0


NTREE=1
; Green top
TREETOP:
			.byte 	%00011000
			.byte 	%00111100
			.byte 	%00111100
			.byte 	%01111110
			.byte 	%01111110
			.byte 	%01111110
			.byte 	%11111111
			.byte 	%11111111
			.byte 	%11111111
			.byte 	%11111111
			.byte 	%01111110
			.byte 	%00111100
			.byte 	%00111100
			.byte 	%00111100
			.byte 	%00111100
			.byte 	%01111110

NTIGERSHIFT=2
TIGERSHIFT:
			ds.b 	16,0
NTIGER=3
; Black Colour
TIGER:
			.byte   %00111100
			.byte   %00111100      
			.byte   %00111100
			.byte   %10100101
			.byte   %10100101
			.byte   %01111110
			.byte   %01110010
			.byte   %01000110
			.byte   %01011110
			.byte   %01110010
			.byte   %01001110
			.byte   %01010010
			.byte   %10111101
			.byte   %10010001
			.byte   %00010000
			.byte   %00011000
NFOOD=4
; Colour Red
FOOD:
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00001100
			.byte 	%00011110
			.byte 	%00111110
			.byte 	%01111110
			.byte 	%11111100
			.byte 	%11111000
			.byte 	%01110000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000

NBARSHIFT=5
BARSHIFT:
			ds.b 	16,0

NBAR=6
BAR:
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110
			.byte 	%11111110

NLIFESHIFT=7
CUBSHIFT:
			ds.b 	16,0

NLIFE=8
CUB:
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%11100111
			.byte 	%10100101
			.byte 	%11111111
			.byte 	%01000010
			.byte 	%10100101
			.byte 	%10100101
			.byte 	%10000001
			.byte 	%10111101
			.byte 	%10011001
			.byte 	%01000010
			.byte 	%00111100
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000

NRIVERSHIFT1=9
RIVERSHIFT1:
			ds.b 	16,0

NRIVERCONVEXA1=10
RIVERCONVEXA1:
			.byte 	%00000011 
			.byte 	%00001110                 
			.byte 	%00111010                 
			.byte 	%11101010                 
			.byte 	%10101010                 
			.byte 	%10101010                 
			.byte 	%10101010                 
			.byte 	%10101010                 
			.byte 	%10101010                 
			.byte 	%10101010                 
			.byte 	%10101010                 
			.byte 	%10101010                 
			.byte 	%11101010                 
			.byte 	%00111010                 
			.byte 	%00001110                 
			.byte 	%00000011                 

NRIVERSHIFT2=11
RIVERSHIFT2:
			ds.b 	16,0

NRIVERCONVEXB2=12
RIVERCONVEXB2:
			.byte 	%11000000
			.byte 	%10110000
			.byte 	%10101100
			.byte 	%10101011
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101011
			.byte 	%10101100
			.byte 	%10110000
			.byte 	%11000000

NRIVERSHIFT3=13
RIVERSHIFT3:
			ds.b 	16,0

NRIVERSTRAIGHT3=14
RIVERSTRAIGHT3:
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%11111111
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%10101010
			.byte 	%11111111
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000


NOBSTACLES=15		
NBULLET=15
; Black
BULLETUP:
			.byte 	%00011000
            .byte 	%00011000
            .byte 	%00011000
            .byte 	%00011000
			.byte 	%00011000
			.byte 	%00011000
			.byte 	%00011000
			.byte 	%00011000
			.byte 	%00011000
			.byte 	%00011000
			.byte 	%00011000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
NPIT=16
;Colour Black
PIT:
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000
			.byte   %00111100
			.byte   %01000010
			.byte   %10110001
			.byte   %10111001
			.byte   %01000010
			.byte   %00111100
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000
NHUNTERLEFT=17
HUNTERLEFT:
			.byte 	%01110000
			.byte 	%01110000
			.byte 	%01110000
			.byte 	%00100000
			.byte 	%11111000
			.byte 	%11111000
			.byte 	%11111000
			.byte 	%11111111
			.byte 	%01111100
			.byte 	%01110000
			.byte 	%01010000
			.byte 	%01010000
			.byte 	%01010000
			.byte 	%01011000
			.byte 	%01100000
			.byte 	%00000000



; PATH Tiles or BLOCK tiles. idk call 'em what you want to.
; These are used to cycle through the 
BLOCKSTART:
BLOCK_START:
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100
			.byte 	#%11111000, #%00000000, #%01111100

; Basic easy block
BLOCKEASY:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100

; Gets a bit smaller in the middle
BLOCKEASY2:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11111000, #%00000000, #%00111100
            .byte   #%11111100, #%00000000, #%01111100
            .byte   #%11111100, #%00000000, #%01111100
            .byte   #%11111110, #%00000000, #%11111100
            .byte   #%11111100, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100

; Right side gets smaller
BLOCKEZS:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11111000, #%00000000, #%00111100
            .byte   #%11111100, #%00000000, #%00111100
            .byte   #%11111110, #%00000000, #%00111100
            .byte   #%11111111, #%00000000, #%00111100
            .byte   #%11111111, #%10000000, #%00111100
            .byte   #%11111111, #%11000000, #%00111100
            .byte   #%11111111, #%01000000, #%00111100
            .byte   #%11111111, #%10000000, #%00111100
            .byte   #%11111111, #%00000000, #%00111100
            .byte   #%11111111, #%11000000, #%00111100
            .byte   #%11111111, #%10000000, #%00111100
            .byte   #%11111111, #%00000000, #%00111100
            .byte   #%11111110, #%00000000, #%00111100
            .byte   #%11111100, #%00000000, #%00111100
            .byte   #%11111000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100

; Left side gets smaller
BLOCKESM:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%01111100
            .byte   #%11110000, #%00000000, #%11111100
            .byte   #%11110000, #%00000001, #%11111100
            .byte   #%11110000, #%00000011, #%11111100
            .byte   #%11110000, #%00000111, #%11111100
            .byte   #%11110000, #%00001111, #%11111100
            .byte   #%11110000, #%00011111, #%11111100
            .byte   #%11110000, #%00111111, #%11111100
            .byte   #%11110000, #%01111111, #%11111100
            .byte   #%11110000, #%00111111, #%11111100
            .byte   #%11110000, #%00011111, #%11111100
            .byte   #%11110000, #%00001111, #%11111100
            .byte   #%11110000, #%00000111, #%11111100
            .byte   #%11110000, #%00000011, #%11111100
            .byte   #%11110000, #%00000001, #%11111100
            .byte   #%11110000, #%00000000, #%11111100
            .byte   #%11110000, #%00000000, #%01111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100

; Winding road
BLOCKROAD:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111110, #%00000001, #%11111100
            .byte   #%11111110, #%00000001, #%11111100
            .byte   #%11111111, #%00000011, #%11111100
            .byte   #%11111111, #%00000111, #%11111100
            .byte   #%11111111, #%00001111, #%11111100
            .byte   #%11111111, #%00000111, #%11111100
            .byte   #%11111111, #%00000011, #%11111100
            .byte   #%11111111, #%00000001, #%11111100
            .byte   #%11111111, #%10000000, #%11111100
            .byte   #%11111111, #%11100000, #%01111100
            .byte   #%11111111, #%11000000, #%11111100
            .byte   #%11111111, #%11000000, #%11111100
            .byte   #%11111111, #%11100000, #%11111100
            .byte   #%11111111, #%11000000, #%11111100
            .byte   #%11111111, #%10000000, #%11111100
            .byte   #%11111111, #%00000000, #%11111100
            .byte   #%11111110, #%00000000, #%01111100
            .byte   #%11110000, #%00000000, #%00111100

;Split into 2 equal(ish) lanes
BLOCKEQ:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00010000, #%00111100
            .byte   #%11110000, #%00010000, #%00111100
            .byte   #%11110000, #%00110000, #%00111100
            .byte   #%11110000, #%00110000, #%00111100
            .byte   #%11110000, #%01110000, #%00111100
            .byte   #%11110000, #%01100000, #%00111100
            .byte   #%11110000, #%01100000, #%00111100
            .byte   #%11110000, #%01100000, #%00111100
            .byte   #%11110000, #%01100000, #%00111100
            .byte   #%11110000, #%01100000, #%00111100
            .byte   #%11110000, #%00110000, #%00111100
            .byte   #%11110000, #%00010000, #%00111100
            .byte   #%11110000, #%00010000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
; One side is harder than the other
BLOCK7:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00010000, #%01111100
            .byte   #%11110000, #%00011000, #%01111100
            .byte   #%11110000, #%00111000, #%01111100
            .byte   #%11110000, #%00111000, #%01111100
            .byte   #%11110000, #%00111000, #%11111100
            .byte   #%11110000, #%00111000, #%11111100
            .byte   #%11110000, #%00111000, #%11111100
            .byte   #%11110000, #%00111000, #%11111100
            .byte   #%11110000, #%00111000, #%11111100
            .byte   #%11110000, #%00011000, #%11111100
            .byte   #%11110000, #%00011000, #%01111100
            .byte   #%11110000, #%00011000, #%01111100
            .byte   #%11110000, #%00011000, #%01111100
            .byte   #%11110000, #%00001000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100

; Three separate lanes
BLOCK8:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00010000, #%01111100
            .byte   #%11110000, #%00110000, #%01111100
            .byte   #%11110000, #%11110000, #%01111100
            .byte   #%11000010, #%11110000, #%01111100
            .byte   #%11000010, #%10100000, #%11111100
            .byte   #%11000110, #%10110000, #%11111100
            .byte   #%10000110, #%11100000, #%11111100
            .byte   #%10000110, #%01100000, #%11111100
            .byte   #%10000110, #%11100000, #%11111100
            .byte   #%10000110, #%00011000, #%11111100
            .byte   #%10000110, #%00011000, #%01111100
            .byte   #%10000110, #%00110000, #%01111100
            .byte   #%10001110, #%01100000, #%01111100
            .byte   #%11000000, #%00100000, #%00111100
            .byte   #%11000000, #%00000000, #%00111100
            .byte   #%11000000, #%00000000, #%00111100
            .byte   #%11100000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100

; Two lanes, one A LOT harder than the other
BLOCK9:
            .byte   #%11100000, #%00000000, #%00111100
            .byte   #%11100000, #%00000000, #%00111100
            .byte   #%11100000, #%00010000, #%01111100
            .byte   #%11100000, #%00011000, #%01111100
            .byte   #%11100000, #%00111000, #%01111100
            .byte   #%11100000, #%00111000, #%11111100
            .byte   #%11100000, #%00111001, #%11111100
            .byte   #%11100000, #%00111011, #%11111100
            .byte   #%11100000, #%00111001, #%11111100
            .byte   #%11100000, #%00111100, #%11111100
            .byte   #%11100000, #%00111110, #%01111100
            .byte   #%11100000, #%00011110, #%01111100
            .byte   #%11100000, #%00011100, #%01111100
            .byte   #%11100000, #%00011000, #%01111100
            .byte   #%11100000, #%00011000, #%01111100
            .byte   #%11100000, #%00001000, #%00111100
            .byte   #%11100000, #%00000000, #%00111100
            .byte   #%11100000, #%00000000, #%00111100
            .byte   #%11100000, #%00000000, #%00111100
            .byte   #%11100000, #%00000000, #%001111000
; Tiny gap to fit through
BLOCK10:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11111000, #%00000000, #%00111100
            .byte   #%11111100, #%00000000, #%00111100
            .byte   #%11111110, #%00000000, #%00111100
            .byte   #%11111111, #%00000000, #%00111100
            .byte   #%11111111, #%00000000, #%01111100
            .byte   #%11111111, #%00000000, #%11111100
            .byte   #%11111111, #%00000001, #%11111100
            .byte   #%11111111, #%00000011, #%11111100
            .byte   #%11111111, #%00000111, #%11111100
            .byte   #%11111111, #%00001111, #%11111100
            .byte   #%11111111, #%00000111, #%11111100
            .byte   #%11111111, #%00001111, #%11111100
            .byte   #%11111111, #%00000111, #%11111100
            .byte   #%11111111, #%00001111, #%11111100
            .byte   #%11111111, #%00000111, #%11111100
            .byte   #%11111111, #%00000011, #%11111100
            .byte   #%11111111, #%00000001, #%11111100
            .byte   #%11111110, #%00000000, #%01111100
            .byte   #%11111100, #%00000000, #%00111100
            .byte   #%11111000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100

; Winding but extremely small gap throughout
BLOCK11:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11111000, #%00000000, #%00111100
            .byte   #%11111110, #%00000000, #%00111100
            .byte   #%11111111, #%10000000, #%00111100
            .byte   #%11111111, #%11000000, #%01111100
            .byte   #%11111111, #%11100001, #%11111100
            .byte   #%11111111, #%00000001, #%11111100
            .byte   #%11111111, #%10000011, #%11111100
            .byte   #%11111111, #%10000111, #%11111100
            .byte   #%11111111, #%11000001, #%11111100
            .byte   #%11111111, #%10000001, #%11111100
            .byte   #%11111111, #%11000011, #%11111100
            .byte   #%11111111, #%11000011, #%11111100
            .byte   #%11111111, #%11100000, #%11111100
            .byte   #%11111111, #%11000000, #%01111100
            .byte   #%11111111, #%11000000, #%11111100
            .byte   #%11111111, #%10000001, #%11111100
            .byte   #%11111111, #%10000011, #%11111100
            .byte   #%11111111, #%11000001, #%11111100
            .byte   #%11111111, #%10000000, #%11111100
            .byte   #%11111111, #%00000000, #%11111100
            .byte   #%11111110, #%00000000, #%01111100
            .byte   #%11110000, #%00000000, #%00111100

; Starts 2 separate, begins winding with separation
BLOCK12:
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00010000, #%00111100
            .byte   #%11110000, #%00010000, #%00111100
            .byte   #%11110000, #%00110000, #%00111100
            .byte   #%11110000, #%00111000, #%00111100
            .byte   #%11110000, #%01111000, #%00111100
            .byte   #%11110000, #%01111000, #%00111100
            .byte   #%11110000, #%01111000, #%00111100
            .byte   #%11110000, #%01111000, #%00111100
            .byte   #%11110000, #%01111000, #%00111100
            .byte   #%11110000, #%01111000, #%00111100
            .byte   #%11110000, #%00111000, #%00111100
            .byte   #%11110000, #%00111000, #%00111100
            .byte   #%11110000, #%00111000, #%00111100
            .byte   #%11110000, #%00111000, #%00111100
            .byte   #%11110000, #%01111100, #%00011100
            .byte   #%11110000, #%11111111, #%00001100
            .byte   #%11000000, #%11111111, #%10001100
            .byte   #%11100000, #%11111111, #%11001100
            .byte   #%11000000, #%11111111, #%10011100
            .byte   #%11000000, #%11111111, #%00111100
            .byte   #%11100000, #%11111110, #%00111100
            .byte   #%11110000, #%11111100, #%00111100
            .byte   #%11000000, #%11111100, #%00111100
            .byte   #%11110000, #%11111100, #%00001100
            .byte   #%11000000, #%01111100, #%00111100
            .byte   #%11110000, #%00111000, #%00111100
            .byte   #%11110000, #%00011000, #%00111100
            .byte   #%11110000, #%00001000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100


;Winding road, ended how I started(does that matter?) should path be wider than 3?
BLOCK13:
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111110, #%00000001, #%11111100
            .byte   #%11111110, #%00000001, #%11111100
            .byte   #%11111111, #%00000001, #%11111100
            .byte   #%11111111, #%00000111, #%11111100
            .byte   #%11111111, #%00001111, #%11111100
            .byte   #%11111111, #%00000111, #%11111100
            .byte   #%11111111, #%00000011, #%11111100
            .byte   #%11111111, #%00000001, #%11111100
            .byte   #%11111111, #%00000000, #%11111100
            .byte   #%11111111, #%11000000, #%01111100
            .byte   #%11111111, #%11100000, #%00111100
            .byte   #%11111111, #%11110000, #%00111100
            .byte   #%11111111, #%11100000, #%00111100
            .byte   #%11111111, #%11000000, #%00111100
            .byte   #%11111111, #%10000000, #%00111100
            .byte   #%11111111, #%00000000, #%00111100
            .byte   #%11111110, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100


;Tried to make one where going down one path makes it significantly harder, is it too hard now?
BLOCK14:
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111100, #%00000000, #%01111100
            .byte   #%11111110, #%00000000, #%11111100
            .byte   #%11111110, #%00000001, #%11111100
            .byte   #%11111100, #%00000001, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00011000, #%01111100
            .byte   #%11111000, #%00011100, #%01111100
            .byte   #%11111000, #%00011100, #%01111100
            .byte   #%11111000, #%00011100, #%01111100
            .byte   #%11111000, #%00011100, #%01111100
            .byte   #%11111000, #%00011000, #%01111100
            .byte   #%11111000, #%00010000, #%01111100
            .byte   #%11111000, #%00010000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
;3 lane
BLOCK15:
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
           	.byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00011000, #%01111100
            .byte   #%11111000, #%00011000, #%01111100
            .byte   #%11111000, #%00011100, #%01111100
            .byte   #%11110000, #%00011100, #%01111100
            .byte   #%11100001, #%00011100, #%01111100
            .byte   #%11000011, #%00011100, #%01111100
            .byte   #%11000011, #%00011000, #%01111100
            .byte   #%11000011, #%00010000, #%01111100
            .byte   #%11100001, #%00010000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100

;Basic shrinking
BLOCK16:
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111100, #%00000000, #%01111100
            .byte   #%11111110, #%00000000, #%11111100
            .byte   #%11111110, #%00000000, #%11111100
            .byte   #%11111111, #%10000000, #%11111100
            .byte   #%11111111, #%10000001, #%11111100
            .byte   #%11111111, #%10000011, #%11111100
            .byte   #%11111111, #%10000001, #%11111100
            .byte   #%11111110, #%00000000, #%11111100
            .byte   #%11111100, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100

;Gets wider (easier) could use with a powerup?? idk
BLOCK17:
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00111100
            .byte   #%11110000, #%00000000, #%00011100
            .byte   #%11110000, #%00000000, #%00011100
            .byte   #%11100000, #%00000000, #%00111100
            .byte   #%11100000, #%00000000, #%00111100
            .byte   #%11100000, #%00000000, #%01111100
            .byte   #%11110000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100

;One where either path is the same size
BLOCK18:
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111100, #%00000000, #%01111100
            .byte   #%11111110, #%00000000, #%11111100
            .byte   #%11111110, #%00000001, #%11111100
            .byte   #%11111100, #%00000001, #%01111100
            .byte   #%11111100, #%00001000, #%00111100
            .byte   #%11111100, #%00011000, #%00111100
            .byte   #%11111100, #%00011000, #%00111100
            .byte   #%11111100, #%00001100, #%00111100
            .byte   #%11111100, #%00001000, #%00111100
            .byte   #%11111100, #%00001111, #%00111100
            .byte   #%11111100, #%00011111, #%00111100
            .byte   #%11111000, #%00010111, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100

BLOCK19:
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
            .byte   #%11111000, #%00000000, #%01111100
BLOCKSEND:
		
			
; NOTE, NOTE, NOTE, DURATION
RIFF:	

			.byte 	232,224,204,5,232,224,214,5,232,224,217,5,232,224,204,10,232,224,204,10,232,224,204,5
			.byte 	232,224,209,10,232,224,204,10,232,224,209,5,232,224,214,5,232,224,217,10
			.byte 	229,221,204,5,229,221,214,5,229,221,217,5,229,221,204,10,229,221,204,10,229,221,204,5
			.byte 	229,221,209,10,229,221,204,10,229,221,209,5,229,221,214,5,229,221,217,10
			.byte 	226,217,209,5,226,217,214,5,226,217,217,5,226,217,209,10,226,217,209,10,226,217,209,5
			.byte 	226,217,209,10,226,217,204,10,226,217,209,5,226,217,214,5,226,217,217,10
			.byte 	229,221,204,5,229,221,214,5,229,221,217,5,229,221,204,10,229,221,204,10,229,221,204,5
			.byte 	224,214,209,10,224,214,204,10,229,221,214,5,229,221,217,5,229,221,224,10,0



	include "zx02_decomp.iasm"
TITLESCREEN:
	incbin "titleData.bin.zx02"
GAMEOVERSCRN:
	incbin "gameOver.bin.zx02"
	