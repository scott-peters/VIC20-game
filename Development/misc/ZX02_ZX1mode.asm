; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Assignment 1
; Decompression of ZX02 compressed title page in ZX1 mode

; De-compressor for ZX02 "-1" files
; ---------------------------------
;
; Decompress ZX02 data in ZX1 mode (6502 optimized format), optimized for
; minimal size: 131 bytes code, 70.6 cycles/byte in test file.
;
; Compress with:
;    zx02 -1 input.bin output.zx1
;
; (c) 2022 DMSC
; Code under MIT license, see LICENSE file.


			processor 6502

;;;;;;; EQUATES ;;;;;;;;
SCRNMEM  	EQU 	$1E00
SCRNMEM2	EQU 	$1F00
COLRAM 		EQU 	$9600
SCRNCOLR	EQU 	$900F


ZP=$7

offset          equ ZP+0
ZX0_src         equ ZP+2
ZX0_dst         equ ZP+4
bitr            equ ZP+6
pntr            equ ZP+7

            ; Initial values for offset, source, destination and bitr
			SEG CODE
			ORG	$1001

BASICSTUB:
			dc.w	.BASICEND
			dc.w	5463
			dc.b	$9e, "4109", $00
.BASICEND
			dc.w	$00


START:
			lda     #$0a
            sta     SCRNCOLR 					; Screen color, Border color
			
			lda 	#$02						; Screen colour
			ldy 	#$ff
.colrloop:		
			sta 	COLRAM-1,y					; Since this is static and constant,
			sta 	COLRAM+#$ff-1,y				; there's no need to encode this
			dey
			bne 	.colrloop


            jsr 	full_decomp
			jmp		.

;--------------------------------------------------
; Decompress ZX0 data (6502 optimized format)

full_decomp
              ; Get initialization block
              ldy #7

copy_init     lda zx0_ini_block-1,y
              sta offset-1,y
              dey
              bne copy_init

; Decode literal: Ccopy next N bytes from compressed file
;    Elias(length)  byte[1]  byte[2]  ...  byte[N]
decode_literal
              jsr   get_elias

cop0          jsr   get_byte
              jsr   put_byte
              bne   cop0

              asl   bitr
              bcs   dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
;    Elias(length)
              jsr   get_elias
dzx0s_copy
              lda   ZX0_dst
              sbc   offset  ; C=0 from get_elias
              sta   pntr
              lda   ZX0_dst+1
              sbc   offset+1
              sta   pntr+1

cop1
              lda   (pntr),y
              inc   pntr
              bne   .cop2
              inc   pntr+1
.cop2         jsr   put_byte
              bne   cop1

              asl   bitr
              bcc   decode_literal

; Copy from new offset (repeat N bytes from new offset)
;    MSB(offset>127)  LSB(offset>127)  Elias(length-1)
;    LSB(offset<128)                   Elias(length-1)
dzx0s_new_offset
              sty   offset+1    ; Clear offset MSB

              ; Get low part of offset, a literal 7 bits
              jsr   get_byte
              lsr
              bcc   offset_ok
              cmp   #$7F
              beq   exit  ; Read a 127, signals the end

              sta   offset+1 ; This is now the "high" part

              ; Get low part of offset, a literal 8 bits
              jsr   get_byte
offset_ok
              sta   offset

              ; And get the copy length.
              jsr   get_elias

              inx
              bcc   dzx0s_copy

; Read an elias-gamma interlaced code.
; ------------------------------------
get_elias
              ; Initialize return value to #1
              ldx   #1
              bne   elias_start

elias_get     ; Read next data bit to result
              txa
              asl   bitr
              rol   elias_start
              tax

elias_start
              ; Get one bit
              asl   bitr
              bne   elias_skip1

              ; Read new bit from stream
              jsr   get_byte
              ;sec   ; not needed, C=1 guaranteed from last bit
              rol   elias_skip1
              sta   bitr

elias_skip1
              bcs   elias_get
              ; Got ending bit, stop reading
exit          
			  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_byte
              lda   (ZX0_src),y
              inc   ZX0_src
              bne   .get_byte1
              inc   ZX0_src+1

.get_byte1    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
put_byte
              sta   (ZX0_dst),y
              inc   ZX0_dst
              bne   .put_byte1
              inc   ZX0_dst+1
.put_byte1    dex
              rts
			  
			  
               ; Initial values for offset, source, destination and bitr
zx0_ini_block
            dc.b 	$00, $00, <DATA, >DATA, $00, $1e, $80

DATA:
	incbin "titlec.bin"
DATAEND:
