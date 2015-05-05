.include "ngin/lfsr8.inc"
.include "ngin/core.inc"

.segment "NGIN_BSS"

ngin_Lfsr8_value: .byte 0

.segment "NGIN_CODE"

; Any value except 0 is fine for seed.
kSeedValue = 1
kEorValue  = $1D

ngin_constructor __ngin_Lfsr8_construct
.proc __ngin_Lfsr8_construct
    ngin_mov8 ngin_Lfsr8_value, #kSeedValue
    rts
.endproc

.proc __ngin_Lfsr8_random
    lda ngin_Lfsr8_value
    ; \todo Runtime assert that the current value isn't 0 (which locks the
    ;       LFSR)
    asl
    bcc noEor
        eor #kEorValue
    noEor:
    sta ngin_Lfsr8_value
    rts
.endproc
