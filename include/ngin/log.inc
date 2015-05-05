.if .not .defined( NGIN_LOG_INC_INCLUDED )
NGIN_LOG_INC_INCLUDED = 1

.include "ngin/lua/lua.inc"

.macro ngin_log severity, message
    __ngin_requireParameter {severity}, "severity"
    __ngin_requireParameter {message}, "message"

    ; \todo Log into our own window(?)
    ; \todo Pass severity, message, and extra arguments to a Lua function
    ;       defined elsewhere.
    ; \note Macros can't have varargs, so have to specify a long enough list
    ;       of arguments (they can be empty)
    ; \todo Handle formatting of: immediates, addresses (need size), registers,
    ;       flags, ...

    .if .xmatch( {severity}, debug )
        ngin_Lua_string .sprintf( "print( string.format( '[ngin] [debug] %%s', %c%s%c ) )", 34, message, 34 )
    .else
        .error "unrecognized log severity"
    .endif
.endmacro

.endif
