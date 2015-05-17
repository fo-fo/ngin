.if .not .defined( NGIN_SHADOW_OAM_INC_INCLUDED )
NGIN_SHADOW_OAM_INC_INCLUDED = 1

.include "ngin/core.inc"
.include "ngin/ppu.inc"

; ngin_ShadowOam_pointer should be set to this value when the shadow OAM has
; become fully filled.
ngin_ShadowOam_kFull = $FF

.global ngin_ShadowOam_buffer
.global ngin_ShadowOam_pointer

.macro ngin_ShadowOam_upload
    ngin_mov8 ppu::oam::dma, #.hibyte( ngin_ShadowOam_buffer )
.endmacro

.global __ngin_ShadowOam_startFrame
.macro ngin_ShadowOam_startFrame
    jsr __ngin_ShadowOam_startFrame
.endmacro

.global __ngin_ShadowOam_endFrame
.macro ngin_ShadowOam_endFrame
    jsr __ngin_ShadowOam_endFrame
.endmacro

.endif
