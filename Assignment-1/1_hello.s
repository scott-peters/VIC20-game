; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 Program 1
; Prints "Goodbye, Cruel World"

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
			ldy 	#$00
.LOOP		lda 	BYE,y
			beq 	.RETURN
			jsr 	$ffd2
			iny
			jmp 	.LOOP
.RETURN 	rts

; 00 here is used as a terminator
; Initially recorded the length
; But it uses more memory. This way it uses 1 byte as a terminator
; instead of incrementing and keeping track of more vars
BYE 		dc.b	"Goodbye, Cruel World.",$00

