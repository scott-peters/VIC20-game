	processor 6502

;;;;; EQUATES ;;;;;;

SCRNHPOS	EQU 	$9000 
SCRNVPOS	EQU 	$9001
SCRNNCOL	EQU 	$9002
SCRNNROW	EQU 	$9003
SCRNRAST	EQU 	$9004
SCRNCHRM	EQU 	$9005
SCRNCOLR	EQU 	$900F
SCRNMEM		EQU 	$1E00
CHRMEM 		EQU 	$1C00
COLORRAM	EQU 	$9600
JOYPORTA	EQU 	$9111
JOYPORTB 	EQU 	$9120


;;;; FOR RNG
SEED		EQU     $61					; 61 to 62 is our 16 bit SEED
SOUND1		EQU     $900a
SOUND2		EQU     $900b
SOUND3		EQU     $900c
RAND		EQU     $60
KSEED1      EQU     $8b
KSEED2      EQU     $8c
KSEED3      EQU     $8d
KSEED4      EQU     $8e
KSEED5      EQU     $8f
TIMER1LOW   EQU     $9116               ; (37142)  Timer 1 low byte
TIMER1HIGH  EQU     $9117               ; (37143)  Timer 1 high byte
TIMER2LOW   EQU     $9118               ; (37144)  Timer 2 low byte
TIMER2HIGH  EQU     $9119               ; (37145)  Timer 2 high byte
NOISE       EQU  	$900D

;;;;;;; CONSTANTS ;;;;;
NCOLUMNS 	EQU 	#24
NROWS 		EQU 	#16

;; COLOURS ;;
BLACK		EQU		#$0
WHITE		EQU		#$1
RED			EQU		#$2
CYAN		EQU		#$3
PURPLE		EQU		#$4
GREEN		EQU		#$5
BLUE		EQU		#$6
YELLOW		EQU		#$7
ORANGE 		EQU 	#$8

SCREENCOLOUR EQU 	136
TORAPOSY 	 EQU 	14
MINTORAX	 EQU 	#9
MAXTORAX	 EQU 	16
TORAROW 	EQU 	$1f38
CUBROW 		EQU 	$1f50
TORACOLR 	EQU 	$9738

;;;;;;;;;;; ZP ;;;;;;;;;;;;

DELTAPIX	EQU 	$07
SCRLSPEED 	EQU 	$08
TORAPOSX	EQU 	$09

HUNTERS		EQU 	$0A
HUNTER1POSY EQU 	$0B
HUNTER2POSY EQU 	$0D
random	 	EQU 	$0F

HUNTER1ADDR EQU 	$11
HUNTER2ADDR EQU 	$13

SHOOTADDR 	EQU 	$15
SHOOTCOLADDR EQU 	$17

SHOOTINPRG 	EQU 	$19

	SEG CODE
	ORG $1001


BASICSTUB:
			dc.w 	.BASICEND
			dc.w 	5463
			dc.b 	$9e, "4109", $00
.BASICEND
			dc.w 	$00


START:
			sei
			jsr 	generate_seed
			ldy 	#$6
.setScrn:	
			lda		SCRNSETTINGS-1,y
			sta 	SCRNHPOS-1,y
			dey
			bne	 	.setScrn
			
			lda 	#SCREENCOLOUR
			sta 	SCRNCOLR

			ldy 	#$ff
.clrLoop:
			lda 	#$00
			sta 	SCRNMEM-1,y
			sta 	SCRNMEM+#$ff-1,y
			dey
			bne 	.clrLoop
			lda 	#0
			sta 	HUNTER1POSY
			sta 	HUNTER2POSY
init:		
			lda 	#%01111111
			sta 	$9122
			lda 	#%01010101
			sta 	random
			lda 	#$ff
			sta 	JOYPORTB
			
			lda 	#$02
			sta 	HUNTERS

			lda 	#$00
			sta 	DELTAPIX
			lda 	#$05
			sta 	SCRLSPEED
			ldy 	#$06
			lda 	#NTREE
			ldx 	#TREECOLOUR

			ldx 	#12
			stx 	TORAPOSX
			jsr 	drawTiger
			
			ldx 	#TREECOLOUR
			ldy 	#07								; 7 columns both on the left and right, reset
.drawTREE:											; Fill with trees
			lda 	#NTREE
			sta 	$1dff,y
			sta 	SCRNMEM+#NCOLUMNS-8,y
			txa
			sta 	$95ff,y
			sta 	COLORRAM+#NCOLUMNS-8,y
			tax
			dey
			bne 	.resetTop
main:		
			lda 	#$0
			cmp 	$9004
			bne 	main

.checkJoy:
			ldy 	TORAPOSX
			lda		JOYPORTA
			ror
			ror
			ror
			ror
			ror
			bcs 	.checkRight
			cpy		#MINTORAX
			beq 	.checkRight
			jsr 	clearTiger
			dec 	TORAPOSX
			jsr 	drawTiger
.checkRight:
			lda 	JOYPORTB
			bmi		.checkscroll

			cpy 	#MAXTORAX
			beq 	.checkscroll
			jsr 	clearTiger
			inc	 	TORAPOSX
			jsr 	drawTiger

.checkscroll:
			lda 	DELTAPIX
			clc
			adc 	SCRLSPEED				; Update DELTAPIX by adding speed
			sta 	DELTAPIX
			bcs 	moveChar				; If carry is set, update screenMem			

bridge:
			jmp 	main


; Move entire screen memory by one row (16 pixels)
moveChar:
			jsr 	collision
			jsr		clearTiger
			ldy 	#$c0

.lower:
			lda 	$1ebf,y
			sta 	$1ed7,y
			lda 	$96bf,y
			sta 	$96d7,y
.next:		dey
			bne 	.lower

			ldy 	#$c0
.upper:
			lda 	$1dff,y
			sta 	$1e17,y
			lda 	$95ff,y
			sta 	$9617,y
			dey
			bne 	.upper

			jsr 	drawTiger

			ldx 	#TREECOLOUR
			ldy 	#07								; 7 columns both on the left and right, reset
.resetTop:											; Fill with trees
			lda 	#NTREE
			sta 	$1dff,y
			sta 	SCRNMEM+#NCOLUMNS-8,y
			txa
			sta 	$95ff,y
			sta 	COLORRAM+#NCOLUMNS-8,y
			tax
			dey
			bne 	.resetTop

			inc 	HUNTER1POSY				; No harm done if there are no hunters 
			inc 	HUNTER2POSY

.checks:
			ldx 	HUNTER1POSY
			cpx 	#TORAPOSY-4
			bcc 	.check2nd

			lda 	#$00
			sta 	HUNTER1POSY
			jmp 	.generateHunter
.check2nd:
			ldx 	HUNTER2POSY
			cpx 	#TORAPOSY-4
			bcc 	bridge

			lda 	#$00
			sta 	HUNTER2POSY

;;; Temporary. Needs a major rework.
.generateHunter:
			jsr 	rng						; Random number
			lsr
			ldx 	#NHUNTER
			ldy 	#BLACK
			bcs 	.huntright				; If odd, generate right hunter

			stx 	$1e00+6					; else, left.
			sty 	COLORRAM+6

			ldx 	#NPIT
			stx 	$1e00+7+NCOLUMNS
			ldx 	#NPIT+1
			stx 	$1e00+7+NCOLUMNS+1
			sty 	COLORRAM+7+NCOLUMNS
			sty 	COLORRAM+7+NCOLUMNS+1

			lda 	#6
			jmp 	final

.huntright:
			ldx 	#NHUNTERRIGHT
			stx 	$1e00+NCOLUMNS-7
			sty 	COLORRAM+NCOLUMNS-7
			
			ldx 	#NPIT
			stx 	$1e00-9+NCOLUMNS*2
			ldx 	#NPIT+1
			stx 	$1e00-9+NCOLUMNS*2+1
			sty 	COLORRAM-9+NCOLUMNS*2
			sty 	COLORRAM-9+NCOLUMNS*2+1

			lda 	#NCOLUMNS-7

final:
			ldy 	#$1E
			ldx 	HUNTER1POSY				; If this is hunter 1, then set X
			bne 	HUNT2X
			sta 	HUNTER1ADDR
			sty 	HUNTER1ADDR+1
			jmp 	getBack
HUNT2X:		
			sta 	HUNTER2ADDR
			sty 	HUNTER2ADDR+1
getBack:
			jmp 	bridge

collision:
			;; Check shot and pit collision, lose life
			ldy 	TORAPOSX
.ll:		
			lda 	TORAROW-#NCOLUMNS,y
			bne 	gameOver
			rts

;; Game Over screen
gameOver:
			jmp	 	.

;; Uses the y register
clearTiger:
			lda 	#NBLANK
			ldx 	TORAPOSX
			sta 	TORAROW-1,x
			sta 	TORAROW+22,x
			sta 	TORAROW+23,x
			sta 	TORAROW+24,x
			rts
drawTiger:
			ldx 	TORAPOSX				; Np even if doesn't change.
			lda 	#NTORA
			sta 	TORAROW-1,x
			sta 	TORAROW+22,x
			sta 	TORAROW+23,x
			sta 	TORAROW+24,x
			lda 	#BLACK
			sta 	TORACOLR-1,x
			sta 	TORACOLR+22,x
			sta 	TORACOLR+23,x
			sta 	TORACOLR+24,x
			rts


; ---------------- PRNG -------------------------
; Generating unique seed
; we know that 139 (8b) -143 (8f) is RND seed value
; for prng - we just need the seed to be unique. So what we do is: we get the seed from rnd seed 4 ($8e)
; from the kernel. Then we xor it with sound 1 ($900a) and store it 1st byte of seed.
; Next, we get the random seed 2 from the kernel, xor is with random seed 3 and then xor again with noise.
; the result we store in the 2nd byte of seed.
generate_seed:
	lda KSEED4
	eor SOUND1
	sta SEED+0
	lda KSEED2
	eor KSEED3
	eor NOISE
	sta SEED+1
	rts

; A 16-bit Galois LFSR (taken from: https://github.com/bbbradsmith/prng_6502/blob/master/galois16.s#L27)
; should generate 0 to ff number in RAND. We do 8 iteration since we need to generate 8 bits
;-------------------------------------------------------
rng:
	ldx #8
	lda SEED+0
a:
	asl
	rol SEED+1
	bcc b		    ; if no bit is shifted out then b
	eor #$39		; If a bit is shfited out xor feedback
b:
	dex
	bne a		    ; decrement the loop counter and continue until it's not 0
	sta SEED+0
	sta RAND		; Store the resulting random number
	rts

;; Gunshot sound
gunshotSound:
			lda 	#$0f
			sta 	$900E

			ldy 	#$ff

.shotloop:	
			sty 	$900C
			sty 	$900D
			ldx		#$ff
.waste:		
			dex 
			bne 	.waste

			stx 	$900C
			stx 	$900D
			inx
			dey
			cpy 	#128
			bne 	.shotloop
			rts

; bulletInitDraw:
; 			lda 	#$ff
; 			sta 	SHOOTINPRG
; 			lda 	#$1E
; 			sta 	SHOOTADDR+1
; 			lda 	TORAPOSX
; 			sta 	SHOOTADDR 
; 			ldy  	HUNTER1POSY				; Need to multiply by num of columns
; .calcloop:	clc							; Addition loop
; 			lda 	SHOOTADDR
; 			adc 	#NCOLUMNS				; No. of columns
; 			sta 	SHOOTADDR
; 			lda 	#00
; 			adc 	SHOOTADDR+1 
; 			sta 	SHOOTADDR+1
; 			dey
; 			bne 	.calcloop
; .DONE:		
; 			lda 	SHOOTADDR+1
; 			eor 	#$88				; XOR hi-base with 0x88 gets the color memory address
; 			sta 	SHOOTCOLADDR+1
; 			lda 	SHOOTADDR
; 			sta 	SHOOTADDR 		; Low 8-bits same.
; 			jsr 	gunshotSound

; drawBULLET:
; 			ldy 	#$00
; 			lda 	#NBLANK
; 			sta 	(SHOOTADDR),y
; 			clc
; 			lda 	#NCOLUMNS
; 			adc 	SHOOTADDR
; 			lda 	SHOOTADDR+1
; 			adc 	#$00
; 			sta 	SHOOTADDR+1
; 			eor 	#$88
; 			sta 	SHOOTCOLADDR+1
; 			lda 	SHOOTADDR
; 			sta 	SHOOTCOLADDR
; 			lda 	#BLACK
; 			sta 	(SHOOTCOLADDR),y
			; rts

SCRNSETTINGS:
			dc.b	$02, $06, $98, $21, $0, $ff		; Sets 9000 to 9005
	


;;;;;; CUSTOM CHARACTERS ;;;;;;

	SEG 	GFX
	ORG 	$1C00

BITMAPS:
NBLANK = 0
BLANK:
			ds.b 16,$00

NTREE=1
TREECOLOUR=5
TREE:
			.byte %00011000
			.byte %00111100
			.byte %01111110
			.byte %11111111
			.byte %11111111
			.byte %11111111
			.byte %11111111
			.byte %01111110
			.byte %00111100
			.byte %00011000
			.byte %00011000
			.byte %00011000
			.byte %00011000
			.byte %00011000
			.byte %00011000
			.byte %00111100
NHUNTER=2
HUNTER:
			.byte %01110000
			.byte %01110000
			.byte %01110000
			.byte %00100000
			.byte %11111000
			.byte %11111000
			.byte %11111000
			.byte %11111111
			.byte %01111100
			.byte %01110000
			.byte %01010000
			.byte %01010000
			.byte %01010000
			.byte %01011000
			.byte %01100000
			.byte %00000000
NHUNTERRIGHT=3
HUNTERRIGHT:
			.byte %00001110
			.byte %00001110
			.byte %00001110
			.byte %00000100
			.byte %00011111
			.byte %00011111
			.byte %00011111
			.byte %11111111
			.byte %00111110
			.byte %00001110
			.byte %00001010
			.byte %00001010
			.byte %00001010
			.byte %00011010
			.byte %00000110
			.byte %00000000
BULLET=4
SHOOT:
			.byte %00000000
			.byte %00000000
			.byte %00000000
			.byte %00000000
			.byte %00000000
			.byte %00010000
			.byte %00010000
			.byte %00010000
			.byte %00010000
			.byte %00010000
			.byte %00010000
			.byte %00010000
			.byte %00010000
			.byte %00010000
			.byte %00010000
			.byte %00010000
NPIT = 5
PIT1:
			.byte %00000000			
			.byte %00000000
			.byte %00000000
			.byte %00001111
			.byte %00011111
			.byte %00111111
			.byte %11110000
			.byte %11100000
			.byte %11000000
			.byte %01100000
			.byte %00110000
			.byte %00011111
			.byte %00001111
			.byte %00000000
			.byte %00000000
			.byte %00000000
PIT2:
			.byte %00000000
			.byte %00000000
			.byte %00000000
			.byte %11110000
			.byte %11111000
			.byte %11111100
			.byte %00011111
			.byte %00001111
			.byte %00000111
			.byte %00001110
			.byte %00011100
			.byte %11111000
			.byte %11110000
			.byte %00000000
			.byte %00000000
			.byte %00000000
NTORA=7
TORA:
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