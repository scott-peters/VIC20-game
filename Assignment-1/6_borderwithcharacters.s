; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 
; Changes the border and screen color when you run the program as well as 
; printing some basic characters on the screen

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

CHROUT		EQU		$ffd2
CHKOUT		EQU		$ffc9


START:		
			ldy 	#$00 		; Init counter
			jsr 	cls			; clear screen
			lda     #$3c  		; This is to change color, can be anything we want 
            sta     $900F 		; Screen color, Border color
			lda 	#$13		; s
			sta		$1e00
			lda		#$3			; c
			sta		$1e01
			lda		#$f			; o
			sta		$1e02
			lda		#$14		; t
			sta		$1e03
			lda		#$14		; t
			sta		$1e04
			lda		#$57		; circle
			sta		$1f40
			lda		#$55		; Left top circle
			sta		$1f4f
			lda		#$49		; Right Top circle
			sta		$1f50
			lda		#$4a		; Left Bottom circle
			sta		$1f65
			lda		#$4b		; Right Bottom circle
			sta		$1f66

			jmp		INF

cls:
			; subroutine for clearning screen
			lda 	#147
			; CHR_CLR_HOME (147)
			jsr 	$ffd2
			; CHROUT
			rts

INF:
			jmp		INF

.RETURN		rts
