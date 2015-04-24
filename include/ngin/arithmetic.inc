.if .not .defined( NGIN_ARITHMETIC_INC_INCLUDED )
NGIN_ARITHMETIC_INC_INCLUDED = 1

.macro ngin_add16 to, what1, what2
    ; If two parameters were given, interpret as to = to + what1
    .if .paramcount = 2
        ngin_add16 {to}, {to}, {what1}
        .exitmac
    .endif

    ; \todo Check .paramcount?
    __ngin_requireParameter {to}, "to"
    __ngin_requireParameter {what1}, "what1"
    __ngin_requireParameter {what2}, "what2"

    ; \todo Check for hibyte offset.

    clc
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
        lda 0+(what1)
    .endif
    .if .match( .left( 1, {what2} ), # )
        .local what2Stripped
        what2Stripped = .right( .tcount( {what2} ) - 1, {what2} )
        adc #.lobyte( what2Stripped )
    .elseif .match( .left( 1, {what2} ), {(} )
        adc what2
    .else
        adc 0+(what2)
    .endif
    sta 0+(to)

    .if .match( .left( 1, {what1} ), # )
        lda #.hibyte( what1Stripped )
    .elseif .match( .left( 1, {what1} ), {(} )
        ; Hibyte is assumed 0 for indirect.
        lda #0
    .else
        lda 1+(what1)
    .endif
    .if .match( .left( 1, {what2} ), # )
        adc #.hibyte( what2Stripped )
    .elseif .match( .left( 1, {what2} ), {(} )
        adc #0
    .else
        adc 1+(what2)
    .endif
    sta 1+(to)
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

.endif
