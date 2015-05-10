.if .not .defined( NGIN_SPRITE_RENDERER_INC_INCLUDED )
NGIN_SPRITE_RENDERER_INC_INCLUDED = 1

.include "ngin/core.inc"

; Terminator byte for sprite definitions
ngin_SpriteRenderer_kDefinitionTerminator = 0

; These adjustments need to be added to X and Y coordinates in sprite
; definitions.
ngin_SpriteRenderer_kAdjustX = 128+4
ngin_SpriteRenderer_kAdjustY = 128+4

; These coordinates define the origin of the sprite view.
; \note These cannot be changed without changes to the sprite renderer logic.
ngin_SpriteRenderer_kOriginX = $8000
ngin_SpriteRenderer_kOriginY = $8000

; These are coordinates that place the sprites origin at the top left corner of
; the screen (compared to the background), when used as the position parameter
; of SpriteRenderer_render.
; Note that sprites cannot be rendered on the topmost scanline.
ngin_SpriteRenderer_kTopLeftX = ngin_SpriteRenderer_kOriginX - \
                                ngin_SpriteRenderer_kAdjustX
ngin_SpriteRenderer_kTopLeftY = ngin_SpriteRenderer_kOriginY - \
                                ngin_SpriteRenderer_kAdjustY - 1

; This bitmask must be ORed in to the attributes of each sprite defined in a
; sprite definition. Its purpose is to force all used attribute bytes to be
; non-zero (since 0 is used as a terminator).
ngin_SpriteRenderer_kAttribute = %000_001_00

; Helper macro for defining hardware sprites within a metasprite
.macro ngin_SpriteRenderer_sprite x_, y_, tile, attribute
    .byte ngin_SpriteRenderer_kAttribute|(attribute) ; Attributes
    .byte ngin_SpriteRenderer_kAdjustX+(x_)          ; X
    .byte ngin_SpriteRenderer_kAdjustY+(y_)          ; Y
    .byte (tile)                                     ; Tile
.endmacro

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
