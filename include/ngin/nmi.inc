.if .not .defined( NGIN_NMI_INC_INCLUDED )
NGIN_NMI_INC_INCLUDED = 1

.global __ngin_Nmi_waitVBlank
.macro ngin_Nmi_waitVBlank
    jsr __ngin_Nmi_waitVBlank
.endmacro

.endif
