; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 Program misc
; Change border colurs

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

start:
			jsr 	cls 		; clear the screen
			ldx 	#0		; load colour black in reg y
.colours
			stx 	$900f 		; color for Screen
			JDA why nops?
			JDA also this loop will blast through the iterations
			JDA almost immediately - if the idea was to cycle
			JDA the colors, this should've been fixed with this
			JDA test program
 			nop
 			nop
 			nop
			inx
			cpx 	#7
			bne 	.colours
			rts

cls:
			; subroutine for clearning screen
			lda 	#147
			; CHR_CLR_HOME (147)
			jsr 	$ffd2
			; CHROUT
			rts
.RETURN 	rts

