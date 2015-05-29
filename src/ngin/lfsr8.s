.include "ngin/lfsr8.inc"
.include "ngin/core.inc"
.include "ngin/assert.inc"

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
    ; A zero locks the LFSR, so give a diagnostic if a zero has ended up
    ; in the value somehow (e.g. bad seed.)
    ngin_assert "RAM.ngin_Lfsr8_value ~= 0"
    asl
    bcc noEor
        eor #kEorValue
    noEor:
    sta ngin_Lfsr8_value
    rts
.endproc
