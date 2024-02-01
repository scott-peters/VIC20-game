; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Final Submission
; Survival Hunt (some macros for the vic-20)

; --------------------------------------
; from test program - 3_megitsuneBM
; --------------------------------------
JTIMER      EQU 	$A2
OSCLO       EQU  	$900A
OSCMID      EQU 	$900B
OSCHI       EQU  	$900C
NOISE       EQU  	$900D
VOL         EQU  	$900E

; --------------------------------------
; from test program - 4_customChar
; --------------------------------------
;;;;;;;;;;; EQUATES ;;;;;;;;;;
CUSTCHRS    EQU 	$1C00
SCRNMEM 	EQU 	$1E00
MULTCOL 	EQU 	$08
NCOLUMNS 	EQU 	22
NROWS		EQU 	23
SCRNCOLOR	EQU 	$9600

; Screen Settings
SCRNCOL		EQU 	$9002
SCRNROW		EQU 	$9003
SCRCHM		EQU 	$9005
SCRCOL 		EQU 	$900F

;;;;;;;;;;; ZP ;;;;;;;;;;;;

POSADDR		EQU 	$7
POSADDRLO 	EQU 	$7
POSADDRHI	EQU 	$8

COLORADDR	EQU 	$9
COLORADDRLO EQU 	$9
COLORADDRHI	EQU 	$A
COLOR 		EQU 	$B

POSX 		EQU 	$C
POSY 		EQU 	$D

; --------------------------------------
; from test program - 6_borderwithcharacters
; --------------------------------------
CHROUT		EQU		$ffd2
CHKOUT		EQU		$ffc9

; --------------------------------------
; from test program - 7_joystick
; --------------------------------------
;;;;;;;;;;; ZP ;;;;;;;;;;;;
OLDPOSX		EQU		$E                         ; FIXME(abhinav): maybe we don't need these anymore?
OLDPOSY		EQU		$F

; --------------------------------------
; from the test program - 8_irq
; --------------------------------------
;;;;;;;;;;; EQUATES ;;;;;;;;;;
CURRINT		EQU 	$14
VIATIMERHI 	EQU 	$9125
VIATIMERLO 	EQU 	$9124


; ----------------------
; for game
; ----------------------
SEED		EQU     $61					; 61 to 62 is our 16 bit SEED
SOUND1		EQU     $900a
SOUND2		EQU     $900b
SOUND3		EQU     $900c
RAND		EQU     $60
KSEED1      EQU     $8b
KSEED2      EQU     $8c
KSEED3      EQU     $8d
KSEED4      EQU     $8e
KSEED5      EQU     $8f
TIMER1LOW   EQU     $9116               ; (37142)  Timer 1 low byte
TIMER1HIGH  EQU     $9117               ; (37143)  Timer 1 high byte
TIMER2LOW   EQU     $9118               ; (37144)  Timer 2 low byte
TIMER2HIGH  EQU     $9119               ; (37145)  Timer 2 high byte
