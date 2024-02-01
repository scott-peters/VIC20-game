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
CUSTCHRS	 = 	$1C00
MULTCOL 	 = 	$08
CLS          =  $E55F
TOPADDADDR 		EQU 	$1e32
TOPADDCOLADDR	EQU 	$9632
; Screen Settings
SCRNCOL		EQU 	$9002
SCRNROW		EQU 	$9003
SCRCHM		EQU 	$9005
SCRNHPOS		EQU 	$9000
SCRNCOLR		EQU 	$900F
SCRCOL 		EQU 	$900F
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
NCOLUMNS 	    EQU 	22
NROWS		    EQU 	23
COLOURRAM		EQU 	$9600
SCRNCOLOR	    EQU 	$9600
SCREENCOLOUR	EQU 	#$88

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


start:
    sei											; Disable intterupts
    cld 										; Clear Decimal
    lda 	#%01111111
    lda		#$ff				; Custom char address = 1C000
    sta		SCRCHM
    lda 	#$08 				; Multicolor Screen
    sta 	SCRCOL
    jsr 	initScreen
    ; set the auxiliary color to some color
    lda 	#%00010000
    sta     $900E
    jsr     draw_river
    jmp     .                   ; jam


draw_river:
    ldx     #3    ; position offset at which the first river sprite is located
    ldy     #3    ; total number of river related sprites.
.riverdraw1:
    txa
    sta     $1f0b-1,y
    lda     #$0e                      ; the charactor color should be light blue ~14
    sta     $970b-1,y
    dex
    dey
    bne     .riverdraw1
    ldx     #3    ; position offset at which the first river sprite is located
    ldy     #3    ; total number of river related sprites.
.riverdraw2:
    txa
    sta     $1f0e-1,y
    lda     #$0e                      ; the charactor color should be light blue ~14
    sta     $970e-1,y
    dex
    dey
    bne     .riverdraw2
    ldx     #3    ; position offset at which the first river sprite is located
    ldy     #3    ; total number of river related sprites.
.riverdraw3:
    txa
    sta     $1f11-1,y
    lda     #$0e                      ; the charactor color should be light blue ~14
    sta     $9711-1,y
    dex
    dey
    bne     .riverdraw3
    ldx     #3    ; position offset at which the first river sprite is located
    ldy     #3    ; total number of river related sprites.
.riverdraw4:
    txa
    sta     $1f14-1,y
    lda     #$0e                      ; the charactor color should be light blue ~14
    sta     $9714-1,y
    dex
    dey
    bne     .riverdraw4
.do_scroll:
    jsr     char_scroll
    ;jsr     smooth_char_scroll
    ;jsr     wait_top
    jsr     .do_scroll
    rts

char_scroll:
    lda     $1f0b
    sta     $fb
    ldy     #0
.charscrollloop:
    lda     $1f0b+1,y
    sta     $1f0b,y
    iny
    cpy     #11
    bne     .charscrollloop
    ;iny
    lda     $fb
    sta     $1f0b,y
    rts

smooth_char_scroll:
    ldy     #2
.rotateouterloop
    ldx     #16
.rotateinnerloop
    lda     $1c10-1,x
    rol
    rol     $1cc0-1,x
    rol     $1cb0-1,x
    rol     $1ca0-1,x
    rol     $1c90-1,x
    rol     $1c80-1,x
    rol     $1c70-1,x
    rol     $1c60-1,x
    rol     $1c50-1,x
    rol     $1c40-1,x
    rol     $1c30-1,x
    rol     $1c20-1,x
    rol     $1c10-1,x
    ; change the original
    dex
    bne     .rotateinnerloop
    dey
    bne     .rotateouterloop
	rts

wait_top
	lda #0
	sta JTIMER 	    ;set the Jiffy Clock to 0.
.expire_top
	lda JTIMER
	cmp #12
	bne .expire_top
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


;;;;;; CUSTOM CHARACTERS ;;;;;;

        SEG     GFX
        ORG     $1C00
; sprites for rivers
; Note the color of the river needs to be set as aux color (11)
; the sprite color will be white (10)
; the screen color is represented by 00
; Bottom represents the sprites which will be at the bottom (meaning the river at the top and ground/path at the bottom)
; Top is the other way around, screen color at the top and the river at the bottom.
BITMAPS:
NBLANK = 0
BLANK:
			ds.b 16,$00
NRIVERCONVEXA1=1
RIVERCONVEXA1:
        .byte %00000011                 ; 03 - when you do ror (at $1c10)
        .byte %00001110                 ; 0e
        .byte %00111010                 ; 3a
        .byte %11101010                 ; ea
        .byte %10101010                 ; aa
        .byte %10101010                 ; aa
        .byte %10101010                 ; aa
        .byte %10101010                 ; aa
        .byte %10101010                 ; aa
        .byte %10101010                 ; aa
        .byte %10101010                 ; aa
        .byte %10101010                 ; aa
        .byte %11101010                 ; ea
        .byte %00111010                 ; 3a
        .byte %00001110                 ; 0e
        .byte %00000011                 ; 03


NRIVERCONVEXB2=2
RIVERCONVEXB2:
        .byte %11000000
        .byte %10110000
        .byte %10101100
        .byte %10101011
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101011
        .byte %10101100
        .byte %10110000
        .byte %11000000

NRIVERSTRAIGHT3=3
RIVERSTRAIGHT3:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %11111111
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11111111
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

NRIVERSTRAIGHT4=4
RIVERSTRAIGHT4:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %11111111
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11111111
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

NRIVERSTRAIGHT5=5
RIVERSTRAIGHT5:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %11111111
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11111111
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

NRIVERSTRAIGHT6=6
RIVERSTRAIGHT6:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %11111111
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11111111
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

NRIVERSTRAIGHT7=7
RIVERSTRAIGHT7:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %11111111
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11111111
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

NRIVERVCONCAVEA8=8
RIVERVCONCAVEA8:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %11000000
        .byte %10110000
        .byte %10101111
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101111
        .byte %10110000
        .byte %11000000
        .byte %00000000
        .byte %00000000
        .byte %00000000


NRIVERVCONCAVEB9=9
RIVERVCONCAVEB9:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000011
        .byte %00001110
        .byte %11111010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11111010
        .byte %00001110
        .byte %00000011
        .byte %00000000
        .byte %00000000
        .byte %00000000

NRIVERSTRAIGHT10=10
RIVERSTRAIGHT10:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %11111111
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11111111
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

NRIVERSTRAIGHT11=11
RIVERSTRAIGHT11:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %11111111
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11111111
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000

NRIVERSTRAIGHT12=12
RIVERSTRAIGHT12:
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %11111111
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11111111
        .byte %00000000
        .byte %00000000
        .byte %00000000
        .byte %00000000
