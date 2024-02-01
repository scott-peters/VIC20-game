; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 Program 2
; Gets input (upto 50 characters) and reverse prints it

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


START:		
			ldy 	#$00 		; Init counter
			jsr 	GETINPUT 
			lda 	#$0d
			jsr 	$ffd2 		; Print a newline
			jsr 	PRINTREV
			rts

GETINPUT:
			jsr 	$ffcf		; Call Kernal routine
			cmp 	#13			; Compare to carriage return
			beq		.RETURN
			sta 	STRING,y
			iny
			cmp 	#50
			beq 	.RETURN 	; Cutoff is 50 characters
			jmp		GETINPUT

PRINTREV:
			lda 	STRING,y
			jsr 	$ffd2
			dey
			bmi 	.RETURN
			jmp 	PRINTREV 
			

.RETURN		rts


STRING 		ds.b	50,0

