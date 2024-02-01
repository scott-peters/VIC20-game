; Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
; CPSC 599.82 - Final Submission
; Survival Hunt (main game file)

; ------------ Basic stub -----------
			processor 6502
			org	$1001

basic_stub:
			dc.w	.basic_end
			dc.w	5463
			dc.b	$9e, "4109", $00
.basic_end
			dc.w	$00

; ----------- includes --------------
; add all the include files here..
    include "constants.s"
    include "title.s"
    include "utils.s"

    if . >= $1e00
        echo "err: attempt to overwrite video memory"
        err
    endif

; ----------- init -------------

.start:
    jmp title

; ------ game init and main loop ------------
.init:
    nop

.game_loop:
    nop