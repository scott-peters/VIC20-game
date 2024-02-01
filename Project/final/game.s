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
; 			7. Small Animals (2 types) for food (powerups)
; 			8. River (horizontally scrolling parallax)
; 			9. Mountains (just in the backgrounds)
; 			10. Bars for level and powerup -- DONE
; Features:
; 	1. Lives -- Shooting Collision, one cub dies -- KIND OF DONE
; 	2. Powerup & Powerup bar
; 	3. Pit Collision -- DONE
; 	4. Hunter
; 	5. Shooting Sound -- DONE
; 	7. Powerup sound or pickup food sound?
; 	8. Boids Algorithm -- NOPE. Spent a day trying to get it to work but nah.
; 	9. PCG to generate tiles I guess -- if time permits!!
; 	10. Metatiles??
; 	11. River Raid PCG and RNG to generate I guess
; 	12. Path tile
; 	13. End Screen
; 	14. Tilemap
; 	15. Harder levels
; TODO:
; 	1. Title screen make NOICE --- Scott
; 	2. Speed
;	3. Vertical Parallax Scrolling if branching into left/right. (keep track. ooooo amazing!!!)
; 	4. Horizontal Parallax Scrolling


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

SCRLO 			EQU 	$16
SCRHI			EQU 	$17
SCR 			EQU 	$16
CRASH 			EQU 	$18

SCREENLIVES		EQU 	$1f08
SCREENLIVESCLR	EQU 	$9708

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


SCREENCOLOUR	EQU 	#$88



;; RANDOM SEED
SEED_LO         EQU 	$4e           
SEED_HI         EQU 	$a7

RANDOM 			EQU 	$19
RANDOMLO		EQU 	$20
RANDOMHI		EQU 	$21


CHARSCROLLCNT	EQU 	$22
CHARCNT 		EQU 	$23
; PATHSTART		EQU 	$23
; PATHSTARTLO		EQU 	$23
; PATHSTARTHI		EQU 	$24

; For now, River is always at the top
PATHTOP 		EQU 	$1e2c
BOTTOMROW 		EQU 	$1ef2

TOPADDADDR 		EQU 	$1e32
TOPADDCOLADDR	EQU 	$9632

JIFFY 			EQU 	$A2


CURRENTBLOCK 	EQU 	$24

	SEG CODE
	ORG $1001


BASICSTUB:
			dc.w 	.BASICEND
			dc.w 	5463
			dc.b 	$9e, "4109", $00
.BASICEND:
			dc.w 	$00


START:
			jsr 	initScreen
			lda 	#$ff
			sta 	SPEED
			; jsr 	showTitle
			jsr 	copyChars
			lda 	#<SCRNMEM
			sta 	SCRLO
			lda 	#>SCRNMEM
			sta 	SCRHI
			jsr 	drawMap
			lda 	#$0
			sta 	DELTASPEED
			sta 	CHARSCROLLCNT
			lda 	#11
			sta 	TIGERPOSX
			lda 	#3
			sta 	LEVEL
			jsr 	drawTiger
			lda 	#5
			sta 	LIVES
			lda 	#$20
			sta 	CHARCNT
			lda 	#$A9
			sta 	RANDOMHI
			lda 	#$30
			sta 	RANDOMLO
mainloop:	
			
			lda 	DELTASPEED
			clc	
			adc 	SPEED
			sta 	DELTASPEED
			bvs 	scrollTree

contMain:
			jsr 	checkJoy
			lda 	LIVES
			beq		gameOver
			jmp 	mainloop
			

;; TODO: PRESS FIRE TO RESTART
gameOver:
			jmp 	.	


;;;; Scroll Tree character by 1px ;;;;
scrollTree SUBROUTINE

			ldy 	$1c1f						
			ldx 	#$15
.loop:
			lda 	$1c0f,x
			sta 	$1c10,x
			dex
			bne 	.loop
			sty 	$1c10
			
			inc 	CHARSCROLLCNT
			ldy 	CHARSCROLLCNT
			cpy 	#16
			bne 	contMain

; Wait for raster to avoid flickering
			lda 	#$0
.wait:		cmp 	$9004
			bne 	.wait

; This scrolls the pathway
.scrollChar:
			jsr 	clearTiger
			ldy 	#$c6
.scrloop:
			lda 	PATHTOP-1,y
			sta 	$1e42-1,y
			dey
			bne 	.scrloop

			lda 	#NBLANK
			ldy 	tilemapRivUp+1
.clrloop:	
			sta 	$1e31-1,y
			dey
			bne 	.clrloop

			jsr 	drawTiger
			sty 	CHARSCROLLCNT
			dec 	CHARCNT
			bne 	mainloop
			

generateObstacle:
			lda 	#$ff
			sta 	CHARCNT
			jsr 	nextRandom
			; lda 	#64
			; sbc 	LEVEL
			; asl
			; cmp 	RANDOMHI
			; bcc 	.newObstacle
			; bit 	RANDOMLO
			; bvc 	.newFoodOrPath
			
			; jmp 	mainloop

.newObstacle:
			lda 	RANDOMHI
			and 	#1
			beq 	.hunter
			ldx 	#NPIT
			jmp 	.direction
.hunter:	
			ldx 	#NFOOD
			
.direction:	
			lda 	RANDOMLO
			and 	#1
			beq 	.right
			txa
			ldy 	#7
			sta 	TOPADDADDR
			lda 	#BLACK
			sta 	TOPADDCOLADDR
			jmp 	mainloop
.right:
			txa
			sta 	TOPADDADDR	
			lda 	#BLACK
			sta 	TOPADDCOLADDR	
bridge:		jmp 	mainloop


checkJoy SUBROUTINE
			clc
			lda 	JIFFY
			cmp 	#3
			bcc 	bridge	

			lda 	$c5
			cmp 	#17
			bne 	.checkRight

			ldx 	TIGERPOSX
			dex
			jsr 	checkTreeSides
			beq 	.checkRight
			jsr 	checkSideCollision
			bne 	.collide
			jsr 	clearTiger
			dec 	TIGERPOSX
			jsr 	drawTiger

.checkRight:
			cmp 	#18
			bne 	.ret
			ldx 	TIGERPOSX
			inx 
			jsr 	checkTreeSides
			beq 	.ret
			jsr 	checkSideCollision
			bne 	.collide
			jsr 	clearTiger
			inc 	TIGERPOSX
			jsr 	drawTiger
.ret:		lda 	#$00
			sta 	JIFFY
			rts
.collide:	
			lda 	LIVES
			beq 	.ret
			dec 	LIVES
			jsr 	rmLife
			rts


;; FIXME: Lives is sooo buggy.
;; This is due to the moving 
rmLife SUBROUTINE
			lda 	#NBLANK
			ldy 	LIVES
			sta 	SCREENLIVES,y
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
			.byte 	$04, $15, $96, $1b, $0, $ff	



;;;;;;;;;; TITLE SCREEN ;;;;;;;;

showTitle SUBROUTINE
			
			rts


drawTiger SUBROUTINE
			lda 	#NTIGER
			ldy 	TIGERPOSX 
			sta 	TIGERPOSY,y
			lda 	#BLACK
			sta 	TIGERCOLRAM,y
			rts
				
clearTiger SUBROUTINE
			lda 	#NBLANK
			ldy 	TIGERPOSX
			sta 	TIGERPOSY,y
			rts



;; check collision at position X
;; Param is in X register -- position X
;; Always checked
;; Sets Zero Flag!!!!!
;; Z = 1 means no collision.
checkFrontCollision SUBROUTINE
			lda 	TIGERPOSY-#NCOLUMNS,x
			cmp 	#NBLANK
			rts

;; This is only needed when moving left/right
;; Takes one param in X which is the X position to check against
;; Sets zero flag!!!
;; Z = 1 means no collision
checkSideCollision SUBROUTINE 
			lda 	TIGERPOSY,x
			cmp 	#NBLANK
			rts

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


copyChars SUBROUTINE
			ldy 	#NBITMAPS*16+1
.copyloop:	
			lda		BITMAPS-1,y
			sta 	CHRMEM-1,y
			dey
			bne		.copyloop
			rts


;;;;;;;;;;;;;; AUDIO ;;;;;;;;;;;;;;;
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

;; Draws trees
;; FIXME: Horrible impl.
;; Be careful! SMC!!!!!!
;; Maybe the PLOT kernel routine might be useful here?
drawMap SUBROUTINE
			lda 	#<SCRNMEM
			sta 	rowSCmod+1
			lda 	#>SCRNMEM
			sta 	rowSCmod+2
			
			ldy 	#NROWS-1
.loop:
			ldx 	tilemapRivUp
			lda 	#NTREE
			jsr 	drawRow
			ldx 	tilemapRivUp+1
			lda 	#NBLANK
			jsr 	drawRow
			ldx 	tilemapRivUp
			lda 	#NTREE
			jsr 	drawRow
			dey
			bne 	.loop

			lda 	#<COLOURRAM
			sta 	rowSCmod+1
			lda 	#>COLOURRAM
			sta 	rowSCmod+2
			
			ldy 	#NROWS-1
.loop2:
			ldx 	tilemapRivUp
			lda 	#GREEN
			jsr 	drawRow
			ldx 	tilemapRivUp+1
			lda 	#GREEN
			jsr 	drawRow
			ldx 	tilemapRivUp
			lda 	#GREEN
			jsr 	drawRow
			dey
			bne 	.loop2
			
			ldy 	#$0
			ldx 	#BLACK
.loop3:
			lda 	#NLIFE							; This saves 2 bytes!
			sta 	SCREENLIVES,y
			txa
			sta 	SCREENLIVESCLR,y
			tax
			iny
			iny
			cpy 	#6
			bne 	.loop3
			rts


;;; Uses x and A
;;; X == Number to print
;;; A = tile to print
drawRow SUBROUTINE
.loop:
rowSCmod:	sta 	SCRNMEM
			inc 	rowSCmod+1
			beq 	.incHi	
.back:		dex
			bne 	.loop
			rts
.incHi:		
			inc 	rowSCmod+2		
			jmp 	.back


;;;; DRAGONFIRE!!!
;;;; 16-bit LFSR
nextRandom SUBROUTINE 
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
NPIT=4
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

NFOOD=6
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


; TODO
NRIVER=7
RIVER:
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
RIVERTWO:
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000

RIVERTHREE:
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
			.byte	%00000000
NBAR=10
BAR:
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
			.byte	%11111110
NLIFE=11
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
NYAMA=12
YAMA:
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000
			.byte 	%00000000

NPATH=13
PATHBLK:
			ds.b 	16,1

; First byte indicates the number of  
tilemapRivUp:
			.byte 	#5,#12
