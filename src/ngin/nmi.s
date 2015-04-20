.include "ngin/nmi.inc"
.include "nmi-private.inc"

.segment "NGIN_BSS"

nmiCount: .byte 0

.segment "NGIN_CODE"

.proc __ngin_nmi
    inc nmiCount
    rti
.endproc

.proc __ngin_waitVBlank
    lda nmiCount
hasntChanged:
    cmp nmiCount
    beq hasntChanged
    rts
.endproc
