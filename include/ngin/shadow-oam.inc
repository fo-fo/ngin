.if .not .defined( NGIN_SHADOW_OAM_INC_INCLUDED )
NGIN_SHADOW_OAM_INC_INCLUDED = 1

; ngin_shadowOamPointer should be set to this value when the shadow OAM has
; become fully filled.
ngin_kShadowOamFull = $FF

.global ngin_shadowOam
.global ngin_shadowOamPointer

.global __ngin_ShadowOam_startFrame
.macro ngin_ShadowOam_startFrame
    jsr __ngin_ShadowOam_startFrame
.endmacro

.global __ngin_ShadowOam_endFrame
.macro ngin_ShadowOam_endFrame
    jsr __ngin_ShadowOam_endFrame
.endmacro

.endif
