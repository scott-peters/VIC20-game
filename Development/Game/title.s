; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Final Submission
; Survival Hunt (title page for our game)

title:
			ldy 	#$00 		; Init counter
			jsr 	cls     	; clear screen
			lda     #$7d  		 
            sta     $900F 		; Screen color, Border color
			
			lda		#$13			;s
			sta		$1e30
			lda		#$15			;u
			sta		$1e31
			lda		#$12			;r
			sta		$1e32
			lda		#$16			;v
			sta		$1e33
			lda		#$09			;i
			sta		$1e34
			lda		#$16			;v
			sta		$1e35
			lda		#$01			;a
			sta		$1e36
			lda		#$0c			;l
			sta		$1e37
			
			lda		#$08			;h
			sta		$1e39
			lda		#$15			;u
			sta		$1e3a
			lda		#$e				;n
			sta		$1e3b
			lda		#$14			;t
			sta		$1e3c
			
			
			lda		#$07			;g
			sta		$1e75
			lda		#$12			;r
			sta		$1e76
			lda		#$f				;o
			sta		$1e77
			lda		#$15			;u
			sta		$1e78
			lda		#$10			;p
			sta		$1e79
			
			lda		#$30			;0
			sta		$1e7b
			lda		#$39			;9
			sta		$1e7c
			
			lda		#$13			;s
			sta		$1e9e
			lda		#$08			;h
			sta		$1e9f
			lda		#$01			;a
			sta		$1ea0
			lda		#$e				;n
			sta		$1ea1
			lda		#$b				;k
			sta		$1ea2
			lda		#$01			;a
			sta		$1ea3
			lda		#$12			;r
			sta		$1ea4
			
			lda		#$07			;g
			sta		$1ea6
			lda		#$01			;a
			sta		$1ea7
			lda		#$e				;n
			sta		$1ea8
			lda		#$5				;e
			sta		$1ea9
			lda		#$13			;s
			sta		$1eaa
			lda		#$08			;h
			sta		$1eab
			
			lda		#$2c			;,
			sta		$1eac
			
			lda		#$01			;a
			sta		$1eca
			lda		#$02			;b
			sta		$1ecb
			lda		#$08			;h
			sta		$1ecc
			lda		#$09			;i
			sta		$1ecd
			lda		#$e				;n
			sta		$1ece
			lda		#$01			;a
			sta		$1ecf
			lda		#$16			;v
			sta		$1ed0
			
			lda		#$13			;s
			sta		$1ed2
			lda		#$01			;a
			sta		$1ed3
			lda		#$18			;x
			sta		$1ed4
			lda		#$05			;e
			sta		$1ed5
			lda		#$e				;n
			sta		$1ed6
			lda		#$01			;a
			sta		$1ed7
			lda		#$2c			;,
			sta		$1ed8
			
			lda		#$13			;s
			sta		$1ef7
			lda		#$03			;c
			sta		$1ef8
			lda		#$f				;o
			sta		$1ef9
			lda		#$14			;t
			sta		$1efa
			lda		#$14			;t
			sta		$1efb
			
			
			lda		#$10			;p
			sta		$1efd
			lda		#$05			;e
			sta		$1efe
			lda		#$14			;t
			sta		$1eff
			lda		#$05			;e
			sta		$1f00
			lda		#$12			;r
			sta		$1f01
			lda		#$13			;s
			sta		$1f02
			lda		#$2c			;,
			sta		$1f03
			
			lda		#$e				;n
			sta		$1f22
			lda		#$01			;a
			sta		$1f23
			lda		#$1a			;z
			sta		$1f24
			lda		#$e				;n
			sta		$1f25
			lda		#$09			;i
			sta		$1f26
			lda		#$e				;n
			sta		$1f27
			
			lda		#$13			;s
			sta		$1f29
			lda		#$08			;h
			sta		$1f2a
			
			lda		#$09			;i
			sta		$1f2b
			lda		#$13			;s
			sta		$1f2c
			
			lda		#$08			;h
			sta		$1f2d
			lda		#$09			;i
			sta		$1f2e
			lda		#$12			;r
			sta		$1f2f
			
			lda		#$22			;"
			sta		$1f4a
			
			lda		#$10			;p
			sta		$1f4b
			lda		#$12			;r
			sta		$1f4c
			
			lda		#$05			;e
			sta		$1f4d
			lda		#$13			;s
			sta		$1f4e
			lda		#$13			;s
			sta		$1f4f
			
			lda		#$13			;s
			sta		$1f51
			
			lda		#$10			;p
			sta		$1f52
			lda		#$01			;a
			sta		$1f53
			lda		#$03			;c
			sta		$1f54
			lda		#$05			;e
			sta		$1f55
			
			lda		#$14			;t
			sta		$1f57
			lda		#$f				;o
			sta		$1f58
			
			lda		#$13			;s
			sta		$1f5a
			
			lda		#$14			;t
			sta		$1f5b
			lda		#$01			;a
			sta		$1f5c
			
			lda		#$12			;r
			sta		$1f5d
			lda		#$14			;t
			sta		$1f5e
			lda		#$22			;"
			sta		$1f5f
			

			lda		#$32			;2
			sta		$1e00		
			lda		#$30			;0
			sta		$1e01
			lda		#$32			;2
			sta		$1e02
			lda		#$32			;2
			sta		$1e03
			
			jmp		INF

INF:
			jmp		INF

.RETURN		rts
				  ;s   u   r   v   i   v   a   l       h  u   n  t
GAMENAME:	.byte $13,$15,$12,$16,$09,$16,$01,$0c,$0,$08,$15,$e,$14

			
GROUP:		;	   g   r   o  u   p      0   9
			.byte $07,$12,$f,$15,$10,$0,$30,$39

NAMES:		;      s   h    a  n  k  a  r      g   a   n  e  s   h    ,
			.byte $13,$08,$01,$e,$b,$01,$12,$0,$07,$01,$e,$5,$13,$08,$2c
			;      a   b   h   i   n  a   v      s   a   x   e   n  a   ,
			.byte $01,$02,$08,$09,$e,$01,$16,$0,$13,$01,$18,$05,$e,$01,$2c
			;      s   c   o  t   t      p    e   t  e   r   s   ,
			.byte $13,$03,$f,$14,$14,$0,$10,$05,$14,$05,$12,$13,$2c
			;      n  a   z   n  i   n     s   h   i   s   h   i   r
			.byte $e,$01,$1a,$e,$09,$e,$0,$13,$08,$09,$13,$08,$09,$12

BEGIN:		;      p   r   e  s    s     s    p   a   c   e      t  o      s   t   a   r   t
			.byte $10,$12,$05,$13,$13,$0,$13,$10,$01,$03,$05,$0,$14,$f,$0,$13,$14,$01,$12,$14