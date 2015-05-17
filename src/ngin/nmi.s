.include "ngin/nmi.inc"
.include "nmi-private.inc"

.segment "NGIN_BSS"

nmiCount: .byte 0

.segment "NGIN_CODE"

.proc __ngin_nmi
    inc nmiCount
    rti
.endproc

.proc __ngin_Nmi_waitVBlank
    ; \todo Runtime assert to make sure that NMI is on.
    lda nmiCount
hasntChanged:
    cmp nmiCount
    beq hasntChanged
    rts
.endproc
