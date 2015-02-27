.if .not .defined( NGIN_CORE_INC_INCLUDED )
NGIN_CORE_INC_INCLUDED = 1

; Enable line continuation with backslash (unfortunately not a .feature)
.linecont +

.macro ngin_entryPoint entrySymbol
    .export __ngin_start := entrySymbol
.endmacro

.endif
