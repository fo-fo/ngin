.if .not .defined( NGIN_NMI_INC_INCLUDED )
NGIN_NMI_INC_INCLUDED = 1

.global __ngin_waitVBlank
.macro ngin_waitVBlank
    jsr __ngin_waitVBlank
.endmacro

.endif
