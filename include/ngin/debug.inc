.if .not .defined( NGIN_DEBUG_INC_INCLUDED )
NGIN_DEBUG_INC_INCLUDED = 1

.include "ngin/core.inc"

; Uploads a debug palette (consisting of both background and sprite colors) to
; PPU. Intention is to provide an easy way to get something to display on the
; screen.
; NOTE: This function polls for vblank, so it can take up to two frames to
; complete.
.global __ngin_Debug_uploadDebugPalette
.macro ngin_Debug_uploadDebugPalette
    jsr __ngin_Debug_uploadDebugPalette
.endmacro

.endif
