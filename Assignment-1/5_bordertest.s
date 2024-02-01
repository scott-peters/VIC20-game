; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 
; Changes the border and screen color when you run the program

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
			lda     #$7b  		; This is to change color, can be anything we want 
            sta     $900F 		; Screen color, Border color


.RETURN		rts
