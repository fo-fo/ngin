.if .not .defined( NGIN_DEBUG_DRAW_INC_INCLUDED )
NGIN_DEBUG_DRAW_INC_INCLUDED = 1

; Share parts of implementation with the logging module.
.include "ngin/log.inc"

; Start a frame of debug data collecting.
.macro ngin_DebugDraw_startFrame
    .ifndef DEBUG
        .exitmac
    .endif

    ndxLuaExecStr "ngin.DebugDraw.startFrame()", 1
.endmacro

; End a frame of debug data collecting. Should be called when PPU updates
; for the frame have been uploaded, so that the results will be displayed
; after the frame has been rendered.
.macro ngin_DebugDraw_endFrame
    .ifndef DEBUG
        .exitmac
    .endif

    ndxLuaExecStr "ngin.DebugDraw.endFrame()", 1
.endmacro

.macro ngin_DebugDraw_printf message, p1, p2, p3, p4, p5, p6, p7, p8
    __ngin_requireParameter {message}, "message"

    .ifndef DEBUG
        .exitmac
    .endif

    ndxLuaExecStrStart

    .byte "ngin.DebugDraw.printf(", ngin_Ascii::kCr, ngin_Ascii::kLf

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
