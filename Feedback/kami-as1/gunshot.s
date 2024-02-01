; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 Progam misc
; Sound that can be used for gunshots in the game. Hold g to listen to it

	processor 6502
	SEG CODE
	ORG	$1001

BASICSTUB:
			; sys 4109 "lol"
			; The address will allways be 4109
			; as the length of the basic stub 
			; doesn't change
			dc.w	.BASICEND
			dc.w	5463
			dc.b	$9e, "4109", $00
.BASICEND
			dc.w	$00

; -------------- from program : 1_hello_misc_change_colours.s ---------------------------------------
start:
			jsr 	cls 		; clear the screen
			ldx 	#3		; load colour black in acc (color table on page 264-265)
			stx 	$900f 		; color for Screen

main:
			stx 	$0286 		; color for CHROUT
			jsr 	message 	; print message
			lda 	#13
			jsr 	$ffd2
			jsr 	max_volume
			;jsr	
			rts

cls:
			; subroutine for clearning screen
			lda 	#147
			; CHR_CLR_HOME (147) page 73
			jsr 	$ffd2
			; CHROUT (page 188)
			rts

message:
			; subroutine for printing message
			ldy 	#$00
.message_loop		lda 	msg,y
			beq 	.return
			jsr 	$ffd2
			iny
			jmp 	.message_loop

.return 	 	rts

msg 	 		dc.b	"PRESS ENTER TO SHOOT!",$00

; -------------- from program : 1_hello_misc_change_colours.s ---------------------------------------

max_volume:
			; we want the volume to be maximum. This is just equivalent to POKE 36878,15 on page(95,96,97) on the manual
    lda #$0f		; volume should be 15(max)
    sta $900e		; at 36878 or 0x900e


enter_pressed:
			 ; information from page 179
    lda $00c5		 ; get current key held down
    cmp #15		 ; if current key is Enter pressed
    beq gunshot
    bne turn_off

gunshot:
    lda #$d9	 	 ; G# note from page 97
    sta $900b		 ; #36875 (page 95)
    jmp enter_pressed


turn_off:
    lda #$00         	 ; 0 should mute (page 96)
    sta $900a		 ; #36874 (page 95)
    sta $900b		 ; #36875 (page 95)
    jmp enter_pressed
