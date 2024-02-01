        processor 6502

;;;;; EQUATES ;;;;;;

SCRNHPOS        EQU $9000
SCRNVPOS        EQU $9001
SCRNNCOL        EQU $9002
SCRNNROW        EQU $9003
SCRNRAST        EQU $9004
SCRNCHRM        EQU $9005
SCRNCOLR        EQU $900F
SCRNMEM         EQU $1E00
CHRMEM          EQU $1C00
COLORRAM        EQU $9600
JOYPORTA        EQU $9111
JOYPORTB        EQU $9120


;;;; FOR RNG
SEED            EQU $61         ; 61 to 62 is our 16 bit SEED
SOUND1          EQU $900a
SOUND2          EQU $900b
SOUND3          EQU $900c
RAND            EQU $60
KSEED1          EQU $8b
KSEED2          EQU $8c
KSEED3          EQU $8d
KSEED4          EQU $8e
KSEED5          EQU $8f
TIMER1LOW       EQU $9116       ; (37142)  Timer 1 low byte
TIMER1HIGH      EQU $9117       ; (37143)  Timer 1 high byte
TIMER2LOW       EQU $9118       ; (37144)  Timer 2 low byte
TIMER2HIGH      EQU $9119       ; (37145)  Timer 2 high byte
NOISE           EQU $900D

;;;;;;; CONSTANTS ;;;;;
NCOLUMNS        EQU #24
NROWS           EQU #16

;; COLOURS ;;
BLACK           EQU #$0
WHITE           EQU #$1
RED             EQU #$2
CYAN            EQU #$3
PURPLE          EQU #$4
GREEN           EQU #$5
BLUE            EQU #$6
YELLOW          EQU #$7
ORANGE          EQU #$8

SCREENCOLOUR    EQU 136
TORAPOSY        EQU 14
MINTORAX        EQU #9
MAXTORAX        EQU 16
TORAROW         EQU $1f38
CUBROW          EQU $1f50
TORACOLR        EQU $9738

;;;;;;;;;;; ZP ;;;;;;;;;;;;

DELTAPIX        EQU $07
SCRLSPEED       EQU $08
TORAPOSX        EQU $09

HUNTER1POSY     EQU $0B
HUNTER2POSY     EQU $0D

HUNTER1ADDR     EQU $11
HUNTER2ADDR     EQU $13

SHOOTADDR       EQU $15
SHOOTCOLADDR    EQU $17

SHOOTINPRG      EQU $19

DDRB            EQU $9122

        SEG     CODE
        ORG     $1001


BASICSTUB:
        dc.w    .BASICEND
        dc.w    5463
        dc.b    $9e, "4109", $00
.BASICEND
        dc.w    $00


START:
        sei                     ; Disable Interrupts
        jsr     generate_seed   ; Generate seed for rng
        ldy     #$6
.setScrn:
        lda     SCRNSETTINGS-1,y
        sta     SCRNHPOS-1,y
        dey
        bne     .setScrn

        lda     #SCREENCOLOUR
        sta     SCRNCOLR

        ldy     #$ff
.clrLoop:
        lda     #$00
        sta     SCRNMEM-1,y
        sta     SCRNMEM+#$ff-1,y
        dey
        bne     .clrLoop
        lda     #0
        sta     HUNTER1POSY
        sta     HUNTER2POSY
init:
        lda     #%01111111      ; Setup Joystick Ports
        sta     DDRB
        lda     #$ff
        sta     JOYPORTB

        lda     #$00
        sta     DELTAPIX
        lda     #$05
        sta     SCRLSPEED
        ldy     #$06
        lda     #NTREE
        ldx     #TREECOLOUR

        ldx     #12             ; 12th Column
        stx     TORAPOSX
        jsr     drawTiger

        ldx     #TREECOLOUR
        ldy     #07             ; 7 columns both on the left and right, reset
.drawTREE:                      ; Fill with trees
        lda     #NTREE
        sta     SCRNMEM-1,y
        sta     SCRNMEM+#NCOLUMNS-8,y
        txa
        sta     COLORRAM-1,y
        sta     COLORRAM+#NCOLUMNS-8,y
        tax
        dey
        bne     .resetTop
main:
        lda     #$0             ; Wait for raster
        cmp     SCRNRAST
        bne     main

.checkJoy:
        ldy     TORAPOSX        ; Check for input
        lda     JOYPORTA
        ror
        ror
        ror
        ror
        ror
        bcs     .checkRight
        cpy     #MINTORAX
        beq     .checkRight
        jsr     clearTiger
        dec     TORAPOSX
        jsr     drawTiger
.checkRight:
        lda     JOYPORTB
        bmi     .checkscroll

        cpy     #MAXTORAX
        beq     .checkscroll
        jsr     clearTiger
        inc     TORAPOSX
        jsr     drawTiger

.checkscroll:
        lda     DELTAPIX
        clc
        adc     SCRLSPEED       ; Update DELTAPIX by adding speed
        sta     DELTAPIX
        bcs     moveChar        ; If carry is set, update screenMem/scroll

bridge:
        jmp     main


; Move entire screen memory by one row (16 pixels)
moveChar:
        jsr     collision       ; Check for collision with tiger before scrolling
        jsr     clearTiger
        ldy     #$c0

.lower: ; Scroll lower half
        lda     $1ebf,y
        sta     $1ed7,y
        lda     $96bf,y
        sta     $96d7,y
.next:  dey
        bne     .lower

        ldy     #$c0            ; Scroll upper 1/2
.upper:
        lda     $1dff,y
        sta     $1e17,y
        lda     $95ff,y
        sta     $9617,y
        dey
        bne     .upper

        jsr     drawTiger

        ldx     #TREECOLOUR     ; Reset Top Line as we don't want repetition
        ldy     #07             ; 7 columns both on the left and right, reset
.resetTop:                      ; Fill with trees
        lda     #NTREE
        sta     SCRNMEM-1,y
        sta     SCRNMEM+#NCOLUMNS-8,y
        txa
        sta     COLORRAM-1,y
        sta     COLORRAM+#NCOLUMNS-8,y
        tax
        dey
        bne     .resetTop

        inc     HUNTER1POSY     ; No harm done if there are no hunters
        inc     HUNTER2POSY

.checks:                        ; Checks to see if hunters needs to be added
        ldx     HUNTER1POSY
        cpx     #TORAPOSY-4     ; -4 as the hunters cannot shoot if they're within 4 rows of the tiger
        bcc     .check2nd

        lda     #$00
        sta     HUNTER1POSY
        jmp     .generateHunter
.check2nd:
        ldx     HUNTER2POSY
        cpx     #TORAPOSY-4
        bcc     bridge

        lda     #$00
        sta     HUNTER2POSY

;;; Temporary. Needs a major rework.
.generateHunter:
        jsr     rng             ; Random number
        lsr
        ldx     #NHUNTER
        ldy     #BLACK
        bcs     .huntright      ; If odd, generate right hunter

        stx     SCRNMEM+6       ; else, left. Near pathway
        sty     COLORRAM+6

        ldx     #NPIT           ; Pit one column in front of the hunter
        stx     SCRNMEM+7+NCOLUMNS; Temporary.
        ldx     #NPIT+1
        stx     SCRNMEM+7+NCOLUMNS+1
        sty     COLORRAM+7+NCOLUMNS
        sty     COLORRAM+7+NCOLUMNS+1

        lda     #6
        jmp     final

.huntright:
        ldx     #NHUNTERRIGHT
        stx     SCRNMEM+NCOLUMNS-7
        sty     COLORRAM+NCOLUMNS-7

        ldx     #NPIT
        stx     SCRNMEM-9+NCOLUMNS*2
        ldx     #NPIT+1
        stx     SCRNMEM-9+NCOLUMNS*2+1
        sty     COLORRAM-9+NCOLUMNS*2
        sty     COLORRAM-9+NCOLUMNS*2+1

        lda     #NCOLUMNS-7

final:
        ldy     #>SCRNMEM
        jmp     getBack
getBack:
        jmp     bridge

collision:
        ;; Check shot and pit collision, lose life, but game over for now
        ldy     TORAPOSX
.ll:
        lda     TORAROW-#NCOLUMNS-1,y
        bne     gameOver
        rts

;; Game Over screen here
gameOver:
        jmp     .

;; Uses the y register
clearTiger:
        lda     #NBLANK         ; Clear tiger and cubs
        ldx     TORAPOSX
        sta     TORAROW-1,x     ; Tiger
        sta     TORAROW+NCOLUMNS-2,x; Cubs
        sta     TORAROW+NCOLUMNS-1,x
        sta     TORAROW+NCOLUMNS,x
        rts
drawTiger:
        ldx     TORAPOSX
        lda     #NTORA
        sta     TORAROW-1,x     ; Tiger
        sta     TORAROW+NCOLUMNS-2,x; Cubs
        sta     TORAROW+NCOLUMNS-1,x
        sta     TORAROW+NCOLUMNS,x
        lda     #BLACK
        sta     TORACOLR-1,x
        sta     TORACOLR+NCOLUMNS-2,x
        sta     TORACOLR+NCOLUMNS-1,x
        sta     TORACOLR+NCOLUMNS,x
        rts

;; Abhinav's Code
; ---------------- PRNG -------------------------
; Generating unique seed
; we know that 139 (8b) -143 (8f) is RND seed value
; for prng - we just need the seed to be unique. So what we do is: we get the seed from rnd seed 4 ($8e)
; from the kernel. Then we xor it with sound 1 ($900a) and store it 1st byte of seed.
; Next, we get the random seed 2 from the kernel, xor is with random seed 3 and then xor again with noise.
; the result we store in the 2nd byte of seed.
generate_seed:
        lda     KSEED4
        eor     SOUND1
        sta     SEED+0
        lda     KSEED2
        eor     KSEED3
        eor     NOISE
        sta     SEED+1
        rts

; A 16-bit Galois LFSR (taken from: https://github.com/bbbradsmith/prng_6502/blob/master/galois16.s#L27)
; should generate 0 to ff number in RAND. We do 8 iteration since we need to generate 8 bits
;-------------------------------------------------------
rng:
        ldx     #8
        lda     SEED+0
a:
        asl
        rol     SEED+1
        bcc     b               ; if no bit is shifted out then b
        eor     #$39            ; If a bit is shfited out xor feedback
b:
        dex
        bne     a               ; decrement the loop counter and continue until it's not 0
        sta     SEED+0
        sta     RAND            ; Store the resulting random number
        rts



;; Gunshot sound
gunshotSound:
        lda     #$0f
        sta     $900E

        ldy     #$ff

.shotloop:
        sty     $900C
        sty     $900D
        ldx     #$ff
.waste:
        dex
        bne     .waste

        stx     $900C
        stx     $900D
        inx
        dey
        cpy     #128
        bne     .shotloop
        rts

;; Started to draw a bullet, but am too tired to do this now
; bulletInitDraw:


SCRNSETTINGS:
        dc.b    $02, $06, $98, $21, $0, $ff 	;Sets 9000 to 9005



;;;;;; CUSTOM CHARACTERS ;;;;;;

		SEG     GFX
		ORG     $1C00

BITMAPS:
NBLANK          = 0
BLANK:
        ds.b    16,$00

NTREE=1
TREECOLOUR=5
TREE:
        .byte   %00011000
        .byte   %00111100
        .byte   %01111110
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %01111110
        .byte   %00111100
        .byte   %00011000
        .byte   %00011000
        .byte   %00011000
        .byte   %00011000
        .byte   %00011000
        .byte   %00011000
        .byte   %00111100
NHUNTER=2
HUNTER:
        .byte   %01110000
        .byte   %01110000
        .byte   %01110000
        .byte   %00100000
        .byte   %11111000
        .byte   %11111000
        .byte   %11111000
        .byte   %11111111
        .byte   %01111100
        .byte   %01110000
        .byte   %01010000
        .byte   %01010000
        .byte   %01010000
        .byte   %01011000
        .byte   %01100000
        .byte   %00000000
NHUNTERRIGHT=3
HUNTERRIGHT:
        .byte   %00001110
        .byte   %00001110
        .byte   %00001110
        .byte   %00000100
        .byte   %00011111
        .byte   %00011111
        .byte   %00011111
        .byte   %11111111
        .byte   %00111110
        .byte   %00001110
        .byte   %00001010
        .byte   %00001010
        .byte   %00001010
        .byte   %00011010
        .byte   %00000110
        .byte   %00000000
BULLET=4
SHOOT:
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00010000
        .byte   %00010000
        .byte   %00010000
        .byte   %00010000
        .byte   %00010000
        .byte   %00010000
        .byte   %00010000
        .byte   %00010000
        .byte   %00010000
        .byte   %00010000
        .byte   %00010000
NPIT=5
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
NTORA=7
TORA:
        .byte   %00111100
        .byte   %00111100       ; eyes in this one? not sure how to make it look good
        .byte   %00111100
        .byte   %10100101       ; the two middle 1's should be white ears
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
