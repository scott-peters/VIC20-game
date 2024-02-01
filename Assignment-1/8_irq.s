; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1 Program 4
; Tests custom bitmaps/character set

	processor 6502
	
	SEG CODE
	ORG	$1001

BASICSTUB:
			dc.w	.BASICEND
			dc.w	5463
			dc.b	$9e, "4109", $00
.BASICEND
			dc.w	$00


;;;;;;;;;;; EQUATES ;;;;;;;;;;
CURRINT		EQU 	$14
VIATIMERHI 	EQU 	$9125
VIATIMERLO 	EQU 	$9124

START:		
			sei 					; Set interrupt flag
			lda 	#>HANDLER
			sta 	$0315
			lda 	#<HANDLER
			sta 	$0314
			lda 	#$00
			sta 	CURRINT
			cli 					; Clear irq flag
			rts 					; Return to basic

HANDLER:
			lda 	CURRINT
			beq 	WAIT			; If first interrupt, then go to wait
			dec 	CURRINT 		; If not, then set curr int to 0
			lda 	#105			; change background and border color
			sta 	$900F
			jmp 	GETBACK			; Go back and continue interrupt
WAIT:		lda 	$9004			; Get current scanline
			bne 	HANDLER 		; If not the first, wait for first
			lda 	#$19			; Set VIA timer. Any other value induces a seizure
			sta 	VIATIMERHI		; Will trigger the interrupt after
			lda 	#$a0			; The ref manual says NTSC-6560 so I just converted that to hex
			sta 	VIATIMERLO		
			lda 	#136
			sta 	$900F
			inc 	CURRINT
GETBACK:	jmp 	$eabf			; Jump back

