.if .not .defined( NGIN_LOG_INC_INCLUDED )
NGIN_LOG_INC_INCLUDED = 1

.include "ngin/lua/lua.inc"
.include "ngin/ascii.inc"
.include "ngin/core.inc"

.define __ngin_log_quotedString( str ) \
    .sprintf( "%c%s%c", ngin_Ascii::kQuote, str, ngin_Ascii::kQuote )

.macro __ngin_log_parameter parameter
    .if .blank( {parameter} )
        .exitmac
    .endif

    .byte "    "

    ; \todo Flags(?)
    ; \todo Signed/unsigned? Fixed point? (Syntax?)

    .if .xmatch( {parameter}, a )
        .byte "REG.A"
    .elseif .xmatch( {parameter}, x )
        .byte "REG.X"
    .elseif .xmatch( {parameter}, y )
        .byte "REG.Y"
    .else
        .if .match( .left( 1, {parameter} ), # )
            .local parameterStripped
            parameterStripped = .right( .tcount( {parameter} ) - 1, {parameter} )
            __ngin_decimalInteger {parameterStripped}
        .else
            ; Default the parameter size to one byte.
            .local parameterSize
            parameterSize .set 1

            __ngin_getOperandStride {parameter}, \
                __ngin_log_parameter_stride

            .if .match( { .left( 2, {parameter} ) }, { 0: } )
                ; Size is defined as bits for (hopefully) clarity,
                ; but needs to be a multiple of 8. Cannot be a symbol right
                ; now, but support could be added for that.
                .assert (.left( 1, {parameter} )) .mod 8 = 0, error
                parameterSize .set (.left( 1, {parameter} )) / 8

                ; Size shouldn't be more than 32 bits.
                .assert parameterSize <= 4, error

                .define __ngin_log_parameter_sizeStripped \
                    .mid( 2, .tcount( {parameter} ) - 2, {parameter} )
            .else
                ; Nothing to strip.
                .define __ngin_log_parameter_sizeStripped \
                    parameter
            .endif

            .local xRelative, yRelative
            xRelative .set ngin_Bool::kFalse
            yRelative .set ngin_Bool::kFalse

            .if .xmatch( { .right( 2, {__ngin_log_parameter_sizeStripped} ) }, \
                         { , x } )
                .define __ngin_log_parameter_relStripped \
                    .left( .tcount( {__ngin_log_parameter_sizeStripped} ) - 2, \
                           {__ngin_log_parameter_sizeStripped} )
                xRelative .set ngin_Bool::kTrue
            .elseif .xmatch( { .right( 2, {__ngin_log_parameter_sizeStripped} ) }, \
                             { , y } )
                .define __ngin_log_parameter_relStripped \
                    .left( .tcount( {__ngin_log_parameter_sizeStripped} ) - 2, \
                           {__ngin_log_parameter_sizeStripped} )
                yRelative .set ngin_Bool::kTrue
            .else
                ; Nothing to strip.
                .define __ngin_log_parameter_relStripped \
                    __ngin_log_parameter_sizeStripped
            .endif

            .byte "bit32.bor("
            .byte ngin_Ascii::kCr, ngin_Ascii::kLf

            ; Loop over and read all of the bytes that we need.
            .repeat parameterSize, i
                .byte "        bit32.lshift( NDX.readMemory( "
                __ngin_decimalInteger {__ngin_log_parameter_relStripped}
                .byte .sprintf( " + %d*%d", i, __ngin_log_parameter_stride )
                .if xRelative
                    .byte " + REG.X"
                .elseif yRelative
                    .byte " + REG.Y"
                .endif
                .byte .sprintf( " ), %d )", 8*i )
                .if i <> parameterSize-1
                    .byte ","
                .endif
                .byte ngin_Ascii::kCr, ngin_Ascii::kLf
            .endrepeat

            ; End bit32.bor:
            .byte "    )"

            .undefine __ngin_log_parameter_sizeStripped
            .undefine __ngin_log_parameter_relStripped
        .endif
    .endif


    .byte ", ", ngin_Ascii::kCr, ngin_Ascii::kLf
.endmacro

; \todo Use recursion to avoid having to specify N parameters manually(?)
; \todo A version which ensures unique address -- ngin_logn (?)
.macro ngin_log severity, message, p1, p2, p3, p4, p5, p6, p7, p8
    __ngin_requireParameter {severity}, "severity"
    __ngin_requireParameter {message}, "message"

    ; \todo Log into our own window(?)

    .if .not .xmatch( {severity}, debug )
        .error "unrecognized log severity"
    .endif

    ndxLuaExecStrStart

    .byte "ngin.log(", ngin_Ascii::kCr, ngin_Ascii::kLf

    .byte "    ", __ngin_log_quotedString .string( severity ), ", "
    .byte ngin_Ascii::kCr, ngin_Ascii::kLf
    .byte "    ", __ngin_log_quotedString message, ", "
    .byte ngin_Ascii::kCr, ngin_Ascii::kLf

    __ngin_log_parameter {p1}
    __ngin_log_parameter {p2}
    __ngin_log_parameter {p3}
    __ngin_log_parameter {p4}
    __ngin_log_parameter {p5}
    __ngin_log_parameter {p6}
    __ngin_log_parameter {p7}
    __ngin_log_parameter {p8}

    ; For simplicity, output nil as the last parameter always, so that a comma
    ; can be appended to all parameters.
    .byte "    nil", ngin_Ascii::kCr, ngin_Ascii::kLf
    .byte ")", ngin_Ascii::kCr, ngin_Ascii::kLf

    ndxLuaExecStrEnd
.endmacro

.endif
