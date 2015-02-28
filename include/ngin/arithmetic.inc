.if .not .defined( NGIN_ARITHMETIC_INC_INCLUDED )
NGIN_ARITHMETIC_INC_INCLUDED = 1

.macro ngin_sbc8 to, what
    lda to
    sbc what
    sta to
.endmacro

.macro ngin_sub16_8 to, what
    sec
    ngin_sbc8 {to}, {what}
    .local noUnderflow
    bcs noUnderflow
        dec 1+(to)
    noUnderflow:
.endmacro

.macro ngin_cmp8 with, what
    lda with
    cmp what
.endmacro

.endif
