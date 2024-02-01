; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 Program 1 (modified version)
; Prints "GOODBYE, CRUEL WORLD!" in different colours

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
			JDA symbolic constant?
			ldx 	#0		; load colour black in acc (color table on page 264-265)
			stx 	$900f 		; color for Screen
.colours
			JDA symbolic constant?
			stx 	$0286 		; color for CHROUT
			jsr 	goodbye 	; print goodbye
			lda 	#13
			jsr 	$ffd2
			inx
			cpx 	#5
			bne 	.colours
			rts

cls:
			; subroutine for clearning screen
			lda 	#147
			; CHR_CLR_HOME (147) page 73
			jsr 	$ffd2
			; CHROUT (page 188)
			rts

goodbye:
			; subroutine for printing "Goodbye, Cruel World"
			ldy 	#$00
.goodbye_loop		lda 	BYE,y
			beq 	.RETURN
			jsr 	$ffd2
			iny
			jmp 	.goodbye_loop
.RETURN 	rts

; 00 here is used as a terminator
; Initially recorded the length
; But it uses more memory. This way it uses 1 byte as a terminator
; instead of incrementing and keeping track of more vars
BYE 		dc.b	"GOODBYE, CRUEL WORLD!",$00

