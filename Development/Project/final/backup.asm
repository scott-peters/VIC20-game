; Screen Size: 24 Columns, 12-14 rows.
; Character Size: 8x16. Max. Sprites = 30
; Screen Colour:
;	Orange background looks like the best. (maybe something using auxiliary?)
; Sprites: 
; 			1. Tree ---- DONE
;			2. Tiger (animated for jumping) -- Can't really do this from a top-down view. Scratch it?
; 			3. Cub Faces ---- DONE
; 			4. Hunter (animated) --- Base is done.
;			5. Bullet ---- DONE
; 			6. Pit -- Fix
; 			7. Small Animals (2 types) for food (powerups) -- DONE
; 			8. River (horizontally scrolling parallax)
; 			9. Mountains (just in the backgrounds) (just river is enough I think)
; 			10. Bars for level and powerup -- DONE
; Features:
; 	1. Lives -- Shooting Collision, one cub dies -- HUGE BUG
; 	2. Powerup & Powerup bar -- DONE. NEED TO IMPLEMENT SWITCH TO ACTIVATE
; 	3. Pit Collision -- DONE
; 	4. Hunter
; 	5. Shooting Sound -- DONE
; 	7. Powerup sound or pickup food sound? -- Nah.
; 	8. Boids Algorithm -- NOPE. Spent a day trying to get it to work but no luck
; 	9. PCG to generate tiles I guess -- if time permits!!
; 	10. Metatiles?? -- Seems the most plausible option given the time. Was reading about poisson disk sampling (maybe something using this?)
; 	11. RNG to generate I guess
; 	12. Path tile -- No need since we can have blank tiles in the middle now!
; 	13. End Screen -- We'll see
; 	14. Tilemap -- ^ see above on metatiles
; 	15. Harder levels -- make food and paths lower
; TODO:
; 	1. Title screen make NOICE --- Scott
; 	2. Speed -- DONE
;	3. Vertical Parallax Scrolling if branching into left/right. (keep track. ooooo amazing!!!) )might not do this.
; 	4. Horizontal Scrolling River or some thing

;;; SPEED BUG -- So this is very hard to fix as it has to do with the raster beam
;;; Only speed values multiple of $20 make the tiger/cub stable 
;;; Other values cause a bit of jitter

		processor 6502

SCRNMEM 		EQU 	$1E00
SCRNRAST		EQU 	$9400
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

CRASH 			EQU 	$18

SCREENLIVES		EQU 	$1f08
SCREENLIVESCLR	EQU 	$9708

SCREENPOWER		EQU 	$1f1a
SCREENPOWERCOLR	EQU 	$971a
NPOWERUPBARS 	EQU 	$19

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

SCREENCOLOUR	EQU 	#$7f


RANDOMLO		EQU 	$20
RANDOMHI		EQU 	$21

JIFFY 			EQU 	$A2


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
			sei											; Disable intterupts
			cld 										; Clear Decimal
			jsr 	initScreen
			lda 	#$20								; BUG. Maybe because of raster? If yes, will moving to interrupts fix it?
			sta 	SPEED
			; jsr 	showTitle
			jsr 	copyChars
			jsr 	drawRow
			lda 	#11
			sta 	TIGERPOSX
			jsr 	drawTiger
			lda 	#6
			sta 	LIVES
			lda 	#$A9
			sta 	RANDOMHI
			lda 	#$30
			sta 	RANDOMLO
			lda 	#$00
			sta 	POWERUP
			sta 	NPOWERUPBARS
			jsr 	drawHealthPower
mainloop:	
			ldx 	#$72								; Pheww.. This took soooo long. Might change it to interrupts
.wait:
			cpx 	$9004
			bne 	.wait
			
			jsr 	clearTiger

			lda 	SPEED								; Speed is only > 20 when powerup is active
			cmp 	#$20
			beq 	.nodec

			lda 	POWERUP
			sec
			sbc 	#$08
			bcc 	.nodec

			lda 	#$00
			sta 	POWERUP
			lda 	#$20
			sta 	SPEED

.nodec:		jsr 	checkKey
			lda 	LIVES
			beq		gameOver

			lda 	DELTASPEED
			clc	
			adc 	SPEED
			sta 	DELTASPEED
			bcs 	scrollChar
			
			jsr 	moveScreen
contMain:
			jmp 	mainloop
			

;; TODO: PRESS SPACE TO RESTART
gameOver:
			jmp 	.	


;;; Scroll the entire char mem by one char (8x16) (16px)
;; COMPLETE -- DO NOT TOUCH THIS
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

			lda 	$1e00-1,y 
			sta 	$1e16-1,y 
			lda 	$9600-1,y 
			sta 	$9616-1,y 
			dey
			bne 	.loop2

			ldy 	#NCOLUMNS							; Empty the top row
			lda 	#NBLANK
.loop3:
			sta 	$1e00-1,y
			dey
			bne 	.loop3

			jsr 	drawRow								; Draw a row of the current tilemap

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
			lda 	DELTASPEED									; Calculate amount to shift the screen
			lsr
			lsr
			lsr
			lsr
			tax
			clc
			adc 	#$04
			lsr
			sta 	$9001
			

			lda 	#$00
			ldy 	#32											; Several ways to do this. 
.clearChr:														; After trying out various methods, 
			sta 	CHRMEM+#NTIGERSHIFT*16-1,y					; I think clearing everything and re-drawing is the best
			sta 	CHRMEM+#NLIFESHIFT*16-1,y
			sta 	CHRMEM+#NBARSHIFT*16-1,y
			dey
			bne 	.clearChr

			txa
			eor 	#$0f										; Get the difference
			tax													; We need to shift the char starting at (0xf - shift) 
			; sbc	#15	

			ldy 	#00											; Copy the original char again to charmem
.copychr:														; shifting the appropriate amount
			lda 	TIGER,y
			sta 	CHRMEM+#NTIGERSHIFT*16,x
			lda 	CUB,y
			sta 	CHRMEM+#NLIFESHIFT*16,x
			lda 	#$fe
			sta 	CHRMEM+#NBARSHIFT*16,x
			inx
			iny
			cpy 	#16
			bne 	.copychr

			jsr 	drawTiger									; Draw the tiger & powerup bar

			rts
		

;; This is used as a bridge to get back to mainloop
;; as it is out of bounds for branching (or used to be)
bridge:		jmp 	mainloop


;; Complete
;; TODO -- Try without interrupts, by reading port directly
;; FIXME -- BUG IN COLLISION AND LIVES
checkKey SUBROUTINE
			lda 	#$00
			sta 	CRASH

			lda 	$c5
			cmp 	#17
			bne 	.checkRight

			ldx 	TIGERPOSX
			beq 	.ret
			dex
			jsr 	checkTreeSides
			beq 	.ret
			jsr 	checkSideCollision
			lda 	CRASH
			bne 	.collide
			dec 	TIGERPOSX

.checkRight:
			cmp 	#18
			bne 	.ret
			ldx 	TIGERPOSX
			cpx		#NCOLUMNS
			beq 	.ret
			inx 
			jsr 	checkTreeSides
			beq 	.ret
			jsr 	checkSideCollision
			lda 	CRASH
			bne 	.collide
			inc 	TIGERPOSX
.ret:		rts
.collide:	
			lda 	LIVES
			beq 	.ret
			dec 	LIVES
			jsr 	rmLife
			rts


rmLife SUBROUTINE
			lda 	#NBLANK
			ldy 	LIVES
			sta 	SCREENLIVES,y
			rts

; Takes X position of side collision to remove obstacle
rmRowObstacle SUBROUTINE
			lda 	#NBLANK
			ldy 	TIGERPOSY,x
			rts

rmColObstacle SUBROUTINE
			lda 	#NBLANK
			ldy 	TIGERPOSY-#NCOLUMNS,x
			rts
	

;;;;;;;;; INIT SCREEN ;;;;;;;;
initScreen SUBROUTINE
			ldy 	#$06
.loop:
			lda 	.screenSettings-1,y
			sta 	SCRNHPOS-1,y
			dey
			bne 	.loop 

			lda 	#SCREENCOLOUR
			sta 	SCRNCOLR
			ldy 	#$ff
.clrloop:
			lda 	#$00
			sta 	SCRNMEM-1,y
			sta 	SCRNMEM+#$ff-1,y
			dey
			bne 	.clrloop
			rts

.screenSettings:
			.byte 	$04, $02, $96, $1d, $0, $ff	



;;;;;;;;;; TITLE SCREEN ;;;;;;;;

;; TODO
showTitle SUBROUTINE
			rts


;; Draw the tiger
drawTiger SUBROUTINE
			lda 	#NTIGERSHIFT
			ldy 	TIGERPOSX 
			sta 	TIGERPOSY,y
			lda 	#NTIGER
			sta 	TIGERPOSY+#NCOLUMNS,y

			lda 	#BLACK
			sta 	TIGERCOLRAM,y
			sta 	TIGERCOLRAM+#NCOLUMNS,y

.cont:		lda 	POWERUP
			lsr
			lsr
			lsr
			lsr
			lsr
			lsr
			tay
			beq 	.ret
			sty 	NPOWERUPBARS
			
.barloop:	
			lda 	#NBAR
			sta 	SCREENPOWER-1,y
			lda 	#NBARSHIFT
			sta 	SCREENPOWER-1+#NCOLUMNS,y
			lda 	#RED
			sta 	SCREENPOWERCOLR-1,y
			sta 	SCREENPOWERCOLR-1+#NCOLUMNS,y
			dey
			bne 	.barloop
.ret:		rts
				
;; Clear the tiger
clearTiger SUBROUTINE
			lda 	#NBLANK
			ldy 	TIGERPOSX
			sta 	TIGERPOSY,y
			sta 	TIGERPOSY+#NCOLUMNS,y

			ldy 	#3
.barloop:	
			sta 	SCREENPOWER-1,y
			sta 	SCREENPOWER-1+#NCOLUMNS,y
			dey
			bne 	.barloop
			rts


;;; TODO: Collision can be done better (and simpler!). But it works for now so not changing it

;; check collision at position X
;; Param is in X register -- position X
;; Always checked
;; Sets Zero Flag!!!!!
;; Z = 1 means no collision.
checkFrontCollision SUBROUTINE
			lda 	TIGERPOSY-#NCOLUMNS,x
			cmp 	#NBLANK
			beq 	.ret
			cmp 	#NFOOD
			bne 	crash
			clc
			lda 	POWERUP
			cmp 	#$ff
			beq 	.ret2
			adc 	#$0f
			sta 	POWERUP
.ret2:		jsr 	rmColObstacle
.ret:		rts

crash:
			lda 	#1
			sta 	CRASH
			jsr 	rmRowObstacle
			rts
			
;; This is only needed when moving left/right
;; Takes one param in X which is the X position to check against
;; Sets zero flag!!!
;; Z = 1 means no collision
checkSideCollision SUBROUTINE 
			lda 	TIGERPOSY,x
			cmp 	#NBLANK
			beq 	.ret
			cmp 	#NFOOD
			bne 	crash
			clc
			lda 	POWERUP
			cmp 	#$ff
			beq 	.ret2
			adc 	#$0f
			sta 	POWERUP
.ret2:		jsr 	rmRowObstacle
.ret:		rts

;; Checks for bounds. Realistically, a tiger CAN move
;; through trees, climb trees, etc. But this is a game.
;; And in this game, the tiger cannot move through trees.
;; Takes one argument in the X register,
;; the X position to check
;; Sets Zero flag!!!
;; Z = 0 means no collision
checkTreeSides SUBROUTINE
			lda 	TIGERPOSY,x
			cmp 	#NTREE
			rts


; Complete
copyChars SUBROUTINE
			ldy 	#NBITMAPS*16+1
.copyloop:	
			lda		BITMAPS-1,y
			sta 	CHRMEM-1,y
			dey
			bne		.copyloop
			rts


;;;;;;;;;;;;;; AUDIO ;;;;;;;;;;;;;;;
; Complete
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


;; TODO - TILEMAP, random generation, etc.
;; PCG
drawRow SUBROUTINE
			ldy 	tilemapRivUp
.loop:		
			lda 	#NTREE
			sta 	SCRNMEM-1,y
			lda 	#GREEN
			sta 	COLOURRAM-1,y
			dey
			bne 	.loop

			ldy 	tilemapRivUp
.loop2:		
			lda 	#NTREE
			sta 	SCRNMEM-1+#NCOLUMNS-6,y
			lda 	#GREEN
			sta 	COLOURRAM-1+#NCOLUMNS-6,y
			dey
			bne 	.loop2
			rts

drawHealthPower SUBROUTINE
			ldy 	#$03
.loop:
			lda 	#NLIFE
			sta 	SCREENLIVES-1,y 
			lda 	#NLIFESHIFT
			sta 	SCREENLIVES+#NCOLUMNS-1,y 
			lda 	#BLACK
			sta 	SCREENLIVESCLR-1,y 
			sta 	SCREENLIVESCLR+#NCOLUMNS-1,y 
			dey
			bne 	.loop
			rts

;;;; DRAGONFIRE!!!
;;;; 16-bit LFSR
genRandom SUBROUTINE 
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
			
BITMAPS:
NBITMAPS=12

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

NBULLET=2
; Black
BULLET:
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
			.byte 	%00011000
			.byte 	%00011000
			.byte 	%00011000
			.byte 	%00011000
			.byte 	%00011000
NTIGERSHIFT=3
TIGERSHIFT:
			ds.b 	16,0
NTIGER=4
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

NPIT=5
; Colour Black
PIT1:
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000
			.byte   %00001111
			.byte   %00011111
			.byte   %00111111
			.byte   %11110000
			.byte   %11100000
			.byte   %11000000
			.byte   %01100000
			.byte   %00110000
			.byte   %00011111
			.byte   %00001111
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000
PIT2:
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000
			.byte   %11110000
			.byte   %11111000
			.byte   %11111100
			.byte   %00011111
			.byte   %00001111
			.byte   %00000111
			.byte   %00001110
			.byte   %00011100
			.byte   %11111000
			.byte   %11110000
			.byte   %00000000
			.byte   %00000000
			.byte   %00000000

NFOOD=7
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

NBAR=8
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
NBARSHIFT=9
BARSHIFT:
			ds.b 	16,0

NLIFE=10
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

NLIFESHIFT=11
CUBSHIFT:
			ds.b 	16,0

; First byte indicates the number of  
tilemapRivUp:
			.byte 	#5,#7
