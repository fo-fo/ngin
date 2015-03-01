.if .not .defined( NGIN_SPRITE_RENDERER_INC_INCLUDED )
NGIN_SPRITE_RENDERER_INC_INCLUDED = 1

.include "ngin/core.inc"

; Terminator byte for sprite definitions
ngin_kSpriteDefinitionTerminator = 0

; These adjustments need to be added to X and Y coordinates in sprite
; definitions.
ngin_kSpriteRendererAdjustX = 128+4
ngin_kSpriteRendererAdjustY = 128+4

; This bitmask must be ORed in to the attributes of each sprite defined in a
; sprite definition. Its purpose is to force all used attribute bytes to be
; non-zero (since 0 is used as a terminator).
ngin_kSpriteRendererAttribute = %000_001_00

.global   __ngin_SpriteRenderer_render
.globalzp __ngin_SpriteRenderer_render_spriteDefinition
.global   __ngin_SpriteRenderer_render_position
.macro ngin_SpriteRenderer_render spriteDefinition, position
    __ngin_requireParameter {spriteDefinition}, "spriteDefinition"
    __ngin_requireParameter {position}, "position"

    ngin_mov16 __ngin_SpriteRenderer_render_spriteDefinition, {spriteDefinition}
    ngin_mov32 __ngin_SpriteRenderer_render_position, {position}

    jsr __ngin_SpriteRenderer_render
.endmacro

.endif
