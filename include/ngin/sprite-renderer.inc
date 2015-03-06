.if .not .defined( NGIN_SPRITE_RENDERER_INC_INCLUDED )
NGIN_SPRITE_RENDERER_INC_INCLUDED = 1

.include "ngin/core.inc"

; Terminator byte for sprite definitions
; \todo Use "ngin_SpriteRenderer_kDefinitionTerminator" instead?
ngin_kSpriteDefinitionTerminator = 0

; These adjustments need to be added to X and Y coordinates in sprite
; definitions.
ngin_kSpriteRendererAdjustX = 128+4
ngin_kSpriteRendererAdjustY = 128+4

; These coordinates define the origin of the sprite view.
; \note These cannot be changed without changes to the sprite renderer logic.
ngin_kSpriteRendererOriginX = $8000
ngin_kSpriteRendererOriginY = $8000

; These are coordinates that place the sprites origin at the top left corner of
; the screen (compared to the background), when used as the position parameter
; of SpriteRenderer_render.
; Note that sprites cannot be rendered on the topmost scanline.
ngin_kSpriteRendererTopLeftX = ngin_kSpriteRendererOriginX - \
                               ngin_kSpriteRendererAdjustX
ngin_kSpriteRendererTopLeftY = ngin_kSpriteRendererOriginY - \
                               ngin_kSpriteRendererAdjustY - 1

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
