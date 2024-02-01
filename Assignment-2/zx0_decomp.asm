; ZX0 Decompressor from https://github.com/dmsc/zx0
; Some labels have been changed to work with dasm
; No changes other than the defining of anonymous labels have been made

; BSD 3-Clause License
;
; Copyright (c) 2021, Einar Saukas
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	processor 6502
;--------------------------------------------------
; Decompress ZX0 data (6502 optimized format)

ZP = $7
;;;;;; FROM ZX0 ;;;;;;
offset          equ ZP+0
ZX0_src         equ ZP+2
ZX0_dst         equ ZP+4
bitr            equ ZP+6
elias_h         equ ZP+7
pntr            equ ZP+8

; Initial values for offset, source, destination and bitr
zx0_ini_block
            dc.b 	$00, $00, <DATA, >DATA, $00, $1e, $80

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
              dec   elias_h
              bpl   cop0

              asl   bitr
              bcs   dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
;    Elias(length)
              jsr   get_elias_carry ; Use "_carry" as C already = 0, it is a little faster.
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
              bne   .cop01
              inc   pntr+1
.cop01        jsr   put_byte

              bne   cop1
              dec   elias_h
              bpl   cop1

              asl   bitr
              bcc   decode_literal

; Copy from new offset (repeat N bytes from new offset)
;    Elias(MSB(offset))  LSB(offset)  Elias(length-1)
dzx0s_new_offset
              ; Read elias code
              jsr   get_elias
              beq   exit  ; Read a $FF, signals the end
              dex
              stx   offset+1
              ; Get low part of offset, a literal 7 bits
              jsr   get_byte
              ; Divide by 2
              lsr   offset+1
              ror  
              sta   offset

              ; Store the extra bit of offset to our bit reserve,
              ; to be read by get_elias. Last bit stays in carry.
              ror   bitr
              ; And get the copy length.
              ; NOTE: can't jump to the copy because we need to increment
              ;       the length by 1, this is 8 extra bytes...
              jsr   get_elias_carry

.dzx0s_new_offset1
              inx
              bne   .dzx0s_new_offset2
              inc   elias_h
.dzx0s_new_offset2
              bne   dzx0s_copy

; Read an elias-gamma interlaced code.
; ------------------------------------
get_elias
              clc
get_elias_carry
              ; Initialize return value to #1
              lda   #1
              sty   elias_h
elias_loop
              ; Get one bit - use ROL to allow injecting one bit at start
              rol   bitr
              bne   .elias_loop1
              ; Read new bit from stream
              tax
              jsr   get_byte
              ;sec   ; not needed, C=1 guaranteed from last bit
              rol   
              sta   bitr
              txa
.elias_loop1
              bcs   elias_get

              ; Got 1, stop reading
              tax
exit          rts

elias_get     ; Read next data bit to LEN
              asl   bitr
              rol   
              rol   elias_h
              bcc   elias_loop

get_byte
              lda   (ZX0_src),y
              inc   ZX0_src
              bne   .get_byte1
              inc   ZX0_src+1
.get_byte1      
              rts

put_byte
              sta   (ZX0_dst),y
              inc   ZX0_dst
              bne   .put_byte1
              inc   ZX0_dst+1
.put_byte1
              dex
              rts

