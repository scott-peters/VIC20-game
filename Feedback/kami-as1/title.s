; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1
; Creating a title page for our game


			processor 6502

SCRNMEM  	EQU 	$1E00
COLRAM 		EQU 	$9600

			SEG CODE
			ORG	$1001

BASICSTUB:
			
			dc.w	.BASICEND
			dc.w	5463
			dc.b	$9e, "4109", $00
.BASICEND
			dc.w	$00


START:		
			ldy 	#$00 		; Init counter
			lda     #$0a 
            sta     $900F 		; Screen color, Border color

; Clears the screen by setting 1e00-1fff to 0
ClrScreen:
			lda 	#32
			ldy 	#$ff
			ldx 	#02
.clrloop:	sta 	SCRNMEM-1,y			; 0x1e00 -- 0x1efe
			sta 	SCRNMEM+#$ff-1,y	; 0x1efe -- 0x1ffd
			txa
			sta 	COLRAM-1,y
			sta 	COLRAM+#$ff-1,y
			tax
			lda 	#32
			dey
			bne 	.clrloop

			lda 	#>GAMENAME
			JDA don't use addresses for zero-page variables, just
			JDA as using magic numbers in any code is a bad practice,
			JDA and in assembly there's the addition bonus that you
			JDA can get bugs that'll be hard to track down
			sta 	$01
			lda 	#<GAMENAME
			sta 	$00

			lda 	#$1e
			sta 	$03
			lda 	#$30
			sta 	$02
			
loop:		ldy 	#$00
change:		lda 	($00),y
			beq 	ret
			sta 	($02),y
			iny
			jmp 	change

ret:		iny
			lda 	($00),y
			beq 	done
			iny 
			sta 	$05			; Hi address of location of next screen code
			lda 	($00),y	
			sta 	$04			; Lo address. Store temp.
			iny
			lda 	($00),y		; Get next color ram pointer
			sta 	$03			
			iny	
			lda 	($00),y
			sta 	$02
			lda 	$05
			sta 	$01
			lda 	$04
			sta 	$00	
			jmp 	loop
			
done:		
			jmp		.


				  			;s   u   r   v   i   v   a   l       h  u   n  t
GAMENAME:	.byte $13,$15,$12,$16,$09,$16,$01,$0c,32,$08,$15,$e,$14,$00

			
GROUP:		;	  	 		g   r   o  u   p      0   9
			.byte #>(GROUP+4),#<(GROUP+4),$1e, $75, $07,$12,$f,$15,$10,32,$30,$39,$00

NAMES:		;      									s   h    a  n  k  a  r      g   a   n  e  s   h    ,
			.byte #>(NAMES+4), #<(NAMES+4), $1e, $9e, $13,$08,$01,$e,$b,$01,$12,32,$07,$01,$e,$5,$13,$08,$2c,$00
			;      a   b   h   i   n  a   v      s   a   x   e   n  a   ,
NAMES1:		.byte #>(NAMES1+4), #<(NAMES1+4), $1e, $ca, $01,$02,$08,$09,$e,$01,$16,32,$13,$01,$18,$05,$e,$01,$2c,$00
														;      s   c   o  t   t      p    e   t  e   r   s   ,
NAMES2:		.byte #>(NAMES2+4), #<(NAMES2+4), $1e, $f7, $13,$03,$f,$14,$14,32,$10,$05,$14,$05,$12,$13,$2c,$00
			;      n  a   z   n  i   n     s   h   i   s   h   i   r
NAMES3:		.byte #>(NAMES3+4), #<(NAMES3+4), $1f, $22, $e,$01,$1a,$e,$09,$e,32,$13,$08,$09,$13,$08,$09,$12,$00

BEGIN:		;      p   r   e  s    s     s    p   a   c   e      t  o      s   t   a   r   t
			.byte #>(BEGIN+4), #<(BEGIN+4), $1f, $61, $10,$12,$05,$13,$13,32,$13,$10,$01,$03,$05,32,$14,$f,32,$13,$14,$01,$12,$14,$00

YEAR:
			.byte #>(YEAR+4), #<(YEAR+4), $1e, $01, $32, $30, $32, $32, $00
END:		.byte $00
