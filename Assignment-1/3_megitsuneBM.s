; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 Program 3
; Plays メギツネmain riff
; Was initially thinking of Lorna Shore or
; Slaughter to Prevail but they're deathcore
; and don't sound good on 8bit systems at all
; So figured Kawaii metal is the way to go :)

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

JTIMER 	=	$A2
OSCLO 	= 	$900A
OSCMID  =	$900B
OSCHI 	= 	$900C
NOISE	= 	$900D
VOL 	= 	$900E


START:
			lda #$0f
			sta VOL
			ldy #00
			ldx #02

.LOADNOTE	
			lda RIFF,y
			beq .CHECKCNT
			
			sta OSCLO
			iny
			lda RIFF,y
			sta OSCMID 
			iny
			lda RIFF,y
			sta OSCHI
			iny
	
			lda #00
			sta JTIMER
.CHECKTIME	
			lda JTIMER
			cmp RIFF,y
			bne .CHECKTIME

			lda #00
			sta OSCLO
			sta OSCMID 
			sta OSCHI
			sta JTIMER
; The low sqr osc doesn't work for some reason without a delay
; Spent days figuring this out.
.CHECKJIFFY	
			lda JTIMER
			beq .CHECKJIFFY
			iny
			bne .LOADNOTE
.CHECKCNT 
			dex
			txa
			beq RETURN
			ldy #00
			jmp .LOADNOTE 

RETURN 		lda #00
			sta VOL
			rts


			

; NOTE, NOTE, NOTE, DURATION
RIFF 		.byte 232,224,204,5,232,224,214,5,232,224,217,5,232,224,204,10,232,224,204,10,232,224,204,5,232,224,209,10,232,224,204,10,232,224,209,5,232,224,214,5,232,224,217,10
			.byte 229,221,204,5,229,221,214,5,229,221,217,5,229,221,204,10,229,221,204,10,229,221,204,5,229,221,209,10,229,221,204,10,229,221,209,5,229,221,214,5,229,221,217,10
			.byte 226,217,209,5,226,217,214,5,226,217,217,5,226,217,209,10,226,217,209,10,226,217,209,5,226,217,209,10,226,217,204,10,226,217,209,5,226,217,214,5,226,217,217,10
			.byte 229,221,204,5,229,221,214,5,229,221,217,5,229,221,204,10,229,221,204,10,229,221,204,5,224,214,209,10,224,214,204,10,229,221,214,5,229,221,217,5,229,221,224,10,0

