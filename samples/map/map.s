.include "ngin/ngin.inc"

.segment "RODATA"

.proc mapData
    ; \todo Define some map data
.endproc

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    ngin_MapData_load #mapData

    jmp *
.endproc

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

.repeat 16
    .byte 0
.endrepeat

.repeat 16
    .byte $FF
.endrepeat
