.if .not .defined( NGIN_ARITHMETIC_INC_INCLUDED )
NGIN_ARITHMETIC_INC_INCLUDED = 1

.macro __ngin_addSub self, clc_, adc_, numBytes, to, what1, what2
    ; If two real parameters were given, interpret as to = to + what1
    .if .blank( {what2} )
        self {to}, {to}, {what1}
        .exitmac
    .endif

    ; \todo Check .paramcount?
    __ngin_requireParameter {to}, "to"
    __ngin_requireParameter {what1}, "what1"
    __ngin_requireParameter {what2}, "what2"

    __ngin_getOperandStride {to},    __ngin_addSub_strideTo
    __ngin_getOperandStride {what1}, __ngin_addSub_strideWhat1
    __ngin_getOperandStride {what2}, __ngin_addSub_strideWhat2

    clc_
    ; \todo Factor out these common portions. Might also want to .definemacroify
    ;       the immediate match and hash-stripping.
    ; \todo Can optimize case where the lobyte of immediate parameter is 0.
    ; \todo Better way to handle indirect parameters?
    .if .match( .left( 1, {what1} ), # )
        .local what1Stripped
        what1Stripped = .right( .tcount( {what1} ) - 1, {what1} )
        lda #.lobyte( what1Stripped )
    .elseif .match( .left( 1, {what1} ), {(} )
        ; Indirect -- assume an 8-bit value.
        lda what1
    .else
        lda 0*__ngin_addSub_strideWhat1+what1
    .endif
    .if .match( .left( 1, {what2} ), # )
        .local what2Stripped
        what2Stripped = .right( .tcount( {what2} ) - 1, {what2} )
        adc_ #.lobyte( what2Stripped )
    .elseif .match( .left( 1, {what2} ), {(} )
        adc_ what2
    .else
        adc_ 0*__ngin_addSub_strideWhat2+what2
    .endif
    sta 0*__ngin_addSub_strideTo+to

    .if .match( .left( 1, {what1} ), # )
        lda #.hibyte( what1Stripped )
    .elseif .match( .left( 1, {what1} ), {(} )
        ; Hibyte is assumed 0 for indirect.
        lda #0
    .else
        lda 1*__ngin_addSub_strideWhat1+what1
    .endif
    .if .match( .left( 1, {what2} ), # )
        adc_ #.hibyte( what2Stripped )
    .elseif .match( .left( 1, {what2} ), {(} )
        adc_ #0
    .else
        adc_ 1*__ngin_addSub_strideWhat2+what2
    .endif
    sta 1*__ngin_addSub_strideTo+to

    ; If 3 byte operands, handle the 3rd byte also.
    ; \todo Would be nice to be able to do stuff like 24+16
    ; \todo This is an almost exact copy of the above block -- factor out.
    .if numBytes = 3
        .if .match( .left( 1, {what1} ), # )
            lda #.lobyte( .hiword( what1Stripped ) )
        .elseif .match( .left( 1, {what1} ), {(} )
            ; Hibyte is assumed 0 for indirect.
            lda #0
        .else
            lda 2*__ngin_addSub_strideWhat1+what1
        .endif
        .if .match( .left( 1, {what2} ), # )
            adc_ #.lobyte( .hiword( what2Stripped ) )
        .elseif .match( .left( 1, {what2} ), {(} )
            adc_ #0
        .else
            adc_ 2*__ngin_addSub_strideWhat2+what2
        .endif
        sta 2*__ngin_addSub_strideTo+to
    .endif
.endmacro

.macro ngin_add16 to, what1, what2
    __ngin_addSub ngin_add16, clc, adc, 2, {to}, {what1}, {what2}
.endmacro

.macro ngin_sub16 to, what1, what2
    __ngin_addSub ngin_sub16, sec, sbc, 2, {to}, {what1}, {what2}
.endmacro

.macro ngin_add24 to, what1, what2
    __ngin_addSub ngin_add24, clc, adc, 3, {to}, {what1}, {what2}
.endmacro

.macro ngin_sub24 to, what1, what2
    __ngin_addSub ngin_sub24, sec, sbc, 3, {to}, {what1}, {what2}
.endmacro

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

.macro ngin_adc8 to, what
    lda to
    adc what
    sta to
.endmacro

.macro ngin_add16_8 to, what
    clc
    ngin_adc8 {to}, {what}
    .local noOverflow
    bcc noOverflow
        inc 1+(to)
    noOverflow:
.endmacro

.macro ngin_add16_8s to, what
    ; \todo Write some tests for this
    ; \todo Make it possible to specify two sources and a destination.
    ; \todo Generalize to get sub16_8s(?)
    ; \todo Some optimization opportunities:
    ;       1) if "what" is a const immediate, the sign extension can be done
    ;          at compile time
    ;       2) if "what" is a constant 0, can optimize to a move
    clc
    lda what
    bmi topBitSet
        ; Top bit not set, so sign extended hibyte is 0.
        adc to
        sta to
        ; If lowbyte overflowed, increase hibyte.
        bcc topBitNotSetDone
            inc 1+(to)
        ; INC doesn't modify carry, so carry is still set here.
        ngin_always bcs topBitNotSetDone
    .local topBitSet
    topBitSet:
        ; Top bit set, so sign extended hibyte is $FF.
        adc to
        sta to
        bcs noOverflow
            dec 1+(to)
        .local noOverflow
        noOverflow:
    .local topBitNotSetDone
    topBitNotSetDone:
.endmacro

.macro ngin_add24_16s to, what
    ; \todo Rethink the whole arithmetic macro thing to avoid code duplication.

    lda 1+(what)
    bmi topBitSet
        ; Top bit not set, so sign extended hibyte is 0.
        ngin_add16 {to}, {what}

        ; If there was an overflow, increase hibyte.
        bcc topBitNotSetDone
            inc 2+(to)
        ; INC doesn't modify carry, so carry is still set here.
        ngin_always bcs topBitNotSetDone
    .local topBitSet
    topBitSet:
        ; Top bit set, so sign extended hibyte is $FF.
        ngin_add16 {to}, {what}

        ; If there was an overflow, increase hibyte.
        bcs noOverflow
            dec 2+(to)
        .local noOverflow
        noOverflow:
    .local topBitNotSetDone
    topBitNotSetDone:
.endmacro

.macro ngin_cmp8 with, what
    __ngin_requireParameter {with}, "with"
    __ngin_requireParameter {what}, "what"

    lda with
    cmp what
.endmacro

.macro __ngin_sbc8NoStore to, what
    lda to
    sbc what
.endmacro

.macro ngin_cmp16 with, what
    __ngin_requireParameter {with}, "with"
    __ngin_requireParameter {what}, "what"

    ; \todo The first parameter should be able to be immediate as well, e.g.
    ;       ngin_cmp16 #123, something
    .if .match( .left( 1, {what} ), # )
        .local whatStripped
        whatStripped = .right( .tcount( {what} ) - 1, {what} )
        ngin_cmp8 0+(with), #.lobyte( whatStripped )
        __ngin_sbc8NoStore 1+(with), #.hibyte( whatStripped )
    .else
        ngin_cmp8 1+(with), 1+(what)
        bne hibytesNotEqual
            ; Hibytes were equal, compare lobytes.
            ngin_cmp8 0+(with), 0+(what)
        .local hibytesNotEqual
        hibytesNotEqual:
    .endif
.endmacro

.macro ngin_cmp24 with, what
    __ngin_requireParameter {with}, "with"
    __ngin_requireParameter {what}, "what"

    ; \todo Refactor with ngin_cmp16

    ; \todo The first parameter should be able to be immediate as well, e.g.
    ;       ngin_cmp24 #123, something
    .if .match( .left( 1, {what} ), # )
        .local whatStripped
        whatStripped = .right( .tcount( {what} ) - 1, {what} )
        ngin_cmp8 0+(with), #.lobyte( whatStripped )
        __ngin_sbc8NoStore 1+(with), #.hibyte( whatStripped )
        __ngin_sbc8NoStore 2+(with), #.lobyte( .hiword( whatStripped ) )
    .else
        ngin_cmp8 2+(with), 2+(what)
        bne hibytesNotEqual
            ; Hibytes were equal, compare next byte.
            ngin_cmp8 1+(with), 1+(what)
            bne hibytesNotEqual2
                ; And the final lowbyte.
                ngin_cmp8 0+(with), 0+(what)
            .local hibytesNotEqual2
            hibytesNotEqual2:
        .local hibytesNotEqual
        hibytesNotEqual:
    .endif
.endmacro

.endif
