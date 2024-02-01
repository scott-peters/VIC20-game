; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Final Submission
; Survival Hunt (some game utils)

IF TEST > 0
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
ENDIF


cls:
			; subroutine for clearning screen
			lda 	#147
			; CHR_CLR_HOME (147)
			jsr 	$ffd2
			; CHROUT
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
randgen:
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
	cmp #0
	sta RAND		; Store the resulting random number
	rts
