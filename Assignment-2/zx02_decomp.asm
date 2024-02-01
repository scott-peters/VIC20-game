; ZX02 Decompressor from https://github.com/dmsc/zx02
; Some labels have been changed to work with dasm
; No changes other than the defining of anonymous labels have been made


; MIT License
;
; Copyright (c) 2020 Daniel Serpell
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

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

ZP = $7
offset          equ ZP+0
ZX0_src         equ ZP+2
ZX0_dst         equ ZP+4
bitr            equ ZP+6
pntr            equ ZP+7


zx0_ini_block:
			dc.b 	$00, $00, <DATA, >DATA, $00, $1e, $80

full_decomp:
            ; Get initialization block
            ldy 	#7

copy_init: 	lda 	zx0_ini_block-1,y
            sta 	offset-1,y
            dey
            bne 	copy_init

; Decode literal: Ccopy next N bytes from compressed file
;    Elias(length)  byte[1]  byte[2]  ...  byte[N]
decode_literal:
            jsr  	get_elias

cop0        lda  	(ZX0_src),y
            inc  	ZX0_src
            bne  	.cop01
            inc  	ZX0_src+1
.cop01      sta  	(ZX0_dst),y
            inc  	ZX0_dst
            bne  	.cop02
            inc  	ZX0_dst+1
.cop02      dex
            bne  	cop0

            asl  	bitr
            bcs  	dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
;    Elias(length)
            jsr   	get_elias
dzx0s_copy:
            lda 	ZX0_dst
            sbc 	offset  ; C=0 from get_elias
            sta 	pntr
            lda 	ZX0_dst+1
            sbc 	offset+1
            sta 	pntr+1

cop1
            lda 	(pntr),y
            inc 	pntr
            bne 	.cop11
            inc 	pntr+1
.cop11      sta 	(ZX0_dst),y
            inc 	ZX0_dst
            bne 	.cop12
            inc 	ZX0_dst+1
.cop12      dex
            bne 	cop1

            asl 	bitr
            bcc 	decode_literal

; Copy from new offset (repeat N bytes from new offset)
;    Elias(MSB(offset))  LSB(offset)  Elias(length-1)
dzx0s_new_offset:
            ; Read elias code for high part of offset
            jsr  	get_elias
            beq  	exit  ; Read a 0, signals the end
            ; Decrease and divide by 2
            dex
            txa
            lsr
            sta  	offset+1

            ; Get low part of offset, a literal 7 bits
            lda   	(ZX0_src),y
            inc   	ZX0_src
            bne   	.dzx0s_new_offset1
            inc   	ZX0_src+1

.dzx0s_new_offset1
              ; Divide by 2
              ror
              sta   offset

              ; And get the copy length.
              ; Start elias reading with the bit already in carry:
              ldx   #1
              jsr   elias_skip1

              inx
              bcc   dzx0s_copy

; Read an elias-gamma interlaced code.
; ------------------------------------
get_elias:
              ; Initialize return value to #1
              ldx   #1
              bne   elias_start

elias_get    ; Read next data bit to result
              asl   bitr
              rol
              tax

elias_start
              ; Get one bit
              asl   bitr
              bne   elias_skip1

              ; Read new bit from stream
              lda   (ZX0_src),y
              inc   ZX0_src
              bne   .elias_start1
              inc   ZX0_src+1
.elias_start1 ;sec   ; not needed, C=1 guaranteed from last bit
              rol 
              sta   bitr

elias_skip1
              txa
              bcs   elias_get
              ; Got ending bit, stop reading
exit
              rts


