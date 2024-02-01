; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Final Submission
; Survival Hunt (game over)
; TODO(abhinav): add a mod function for top and bottom to stay within line and erase vals
; --------------
JTIMER       =  $A2
CHR_CLR_HOME =  $93
CHROUT		 =	$FFD2
SCRCOL 		 = 	$900F
SCRNMEM 	 = 	$1E00
CLS          =  $E55F
TOPADDADDR 		EQU 	$1e32
TOPADDCOLADDR	EQU 	$9632
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
CHRMEM 			EQU 	$1C00
COLOURRAM		EQU 	$9600
; --------------

	processor 6502
	
	SEG CODE
	org	$1001

.basic_start:
			dc.w	.basic_end
			dc.w	5463
			dc.b	$9e, "4109", $00
.basic_end
			dc.w	$00


start
    jsr CLS
	jsr color
	ldx #$0
	jsr load_chars
    jmp maybe_scroll
	rts

color
	ldx #$2e
	stx SCRCOL
	rts

load_chars
    ; store top sprite at e0 - e1 (starting at $1e16)
    lda #$16
    sta $e0
    lda #$1e
    sta $e1
    ; store bottom sprite at f0 - f1 (starting at $1fe3)
    lda #$e3
    sta $f0
    lda #$1f
    sta $f1
    rts

move_right_top
    ; move sprite to the right.
    lda $e0
    clc
    adc #$1
    sta $e0
    rts

move_left_bottom
    ; move left
    lda $f0
    sec
    sbc #$1
    sta $f0
    rts
    
erase_current_top
    lda #$20
    ldy #$0
    sta ($e0),Y
    rts

erase_current_bottom
    lda #$20
    ldy #$0
    sta ($f0),Y
    rts

draw_current_top
    ; draw_sprite_top
    lda #$3e
    ldy #$0
    sta ($e0),Y
    rts

draw_current_bottom
    ; draw_sprite_bottom
    lda #$3c
    ldy #$0
    sta ($f0),Y
    rts


maybe_scroll
    jsr erase_current_top
    jsr wait_top
    jsr move_right_top
    jsr draw_current_top

    jsr erase_current_bottom
    jsr wait_bottom
    jsr move_left_bottom
    jsr draw_current_bottom
    inx
    cpx #$16
    beq restart
	jmp maybe_scroll

restart
	jsr load_chars
	jmp maybe_scroll

wait_top
	lda #0
	sta JTIMER 	    ;set the Jiffy Clock to 0.
.expire_top
	lda JTIMER
	cmp #12
	bne .expire_top
	rts

wait_bottom
	lda #0
	sta JTIMER 	    ;set the Jiffy Clock to 0.
.expire_bottom
	lda JTIMER
	cmp #6
	bne .expire_bottom
	rts

; ----- from test program ------------
; Clears the screen by setting 1e00-1fff to 0
ClrScreen:
			lda 	#00
			ldy 	#$ff

.clrloop:	sta 	$1E00-1,y			; 0x1e00 -- 0x1efe
			sta 	$1E00+#$ff-1,y	    ; 0x1efe -- 0x1ffd
			dey
			bne 	.clrloop
			; lda 	#00					; Set the remaining two bytes.
			; sta 	$1ffe				; Not doing this doesn't cause
			; sta 	$1fff				; any issues. Why?
			rts

CopyChars:
			ldy 	#NUMCHARS*16+1		; 8x8 Sprites. Change to 16 for 16x8
.copyloop:
			lda		BITMAPS-1,y
			sta 	$1C00-1,y
			dey
			bne		.copyloop
			rts

; sprites for rivers
; Note the color of the river needs to be set as aux color (11)
; the sprite color will be white (10)
; the screen color is represented by 00
; Bottom represents the sprites which will be at the bottom (meaning the river at the top and ground/path at the bottom)
; Top is the other way around, screen color at the top and the river at the bottom.
BITMAPS:
BLANK:
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00
		.byte $00

BOTTOMCURVEA:
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111011
        .byte %11101010
        .byte %10000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

BOTTOMCURVEB:
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %10111110
        .byte %00101110
        .byte %00001000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

BOTTOMSTRAIGHT:
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %10101010
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

TOPSTRAIGHT:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %10101010
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111

TOPCURVEA:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00001000
        .byte %00001010
        .byte %00101111
        .byte %00101111
        .byte %10111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111

TOPCURVEB:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %10000000
        .byte %11100000
        .byte %11111000
        .byte %11111110
        .byte %11111110
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111

