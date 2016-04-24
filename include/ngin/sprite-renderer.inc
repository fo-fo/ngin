.if .not .defined( NGIN_SPRITE_RENDERER_INC_INCLUDED )
NGIN_SPRITE_RENDERER_INC_INCLUDED = 1

.include "ngin/core.inc"

; The metasprite header is used to allow animations to be specified.
; If the SpriteAnimator module is not used, these fields can be left empty.
.struct ngin_SpriteRenderer_Header
    ; Delay until the next frame
    delay               .byte

    ; Link to the next frame
    next                .word

    ; Animation event callback
    eventCallback       .word

    ; The metasprite itself
    metasprite          .tag __ngin_EmptyStruct
.endstruct

; Terminator byte for metasprite
ngin_SpriteRenderer_kMetaspriteTerminator = 0

; These adjustments need to be added to X and Y coordinates in metasprites.
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

; This bitmask must be ORed in to the attributes of each hardware sprite defined
; in a metasprite. Its purpose is to force all used attribute bytes to be
; non-zero (since 0 is used as a terminator).
ngin_SpriteRenderer_kAttribute = %000_001_00

; Helper macro for defining metasprite header
.global __ngin_SpriteRenderer_nullCallback
.macro ngin_SpriteRenderer_metasprite delay, next, eventCallback
    .local thisMetasprite
    thisMetasprite:

    .if .not .blank( {delay} )
        .byte (delay)
    .else
        ; By default, use a delay of 256.
        .byte 0
    .endif

    ; By default, point the next pointer at the current metasprite.
    .if .not .blank( {next} )
        .addr (next)
    .else
        .addr thisMetasprite
    .endif

    ; By default, point the callback to no-op handler.
    .if .not .blank( {eventCallback} )
        .addr (eventCallback)
    .else
        .addr __ngin_SpriteRenderer_nullCallback
    .endif
.endmacro

; Helper macro for defining hardware sprites within a metasprite
.macro ngin_SpriteRenderer_sprite x_, y_, tile, attribute
    .byte ngin_SpriteRenderer_kAttribute|(attribute) ; Attributes
    .byte ngin_SpriteRenderer_kAdjustX+(x_)          ; X
    .byte ngin_SpriteRenderer_kAdjustY+(y_)          ; Y
    .byte (tile)                                     ; Tile
.endmacro

.macro ngin_SpriteRenderer_endMetasprite
    .byte ngin_SpriteRenderer_kMetaspriteTerminator
.endmacro

.global   __ngin_SpriteRenderer_render
.globalzp __ngin_SpriteRenderer_render_metasprite
.global   __ngin_SpriteRenderer_render_position
.global   __ngin_SpriteRenderer_render_attributeEor
.macro ngin_SpriteRenderer_render metasprite, position, attributeEor
    __ngin_requireParameter {metasprite}, "metasprite"
    __ngin_requireParameter {position}, "position"

    ngin_mov16 __ngin_SpriteRenderer_render_metasprite, {metasprite}
    ngin_mov32 __ngin_SpriteRenderer_render_position, {position}
    .if .not .blank( {attributeEor} )
        ngin_mov8  __ngin_SpriteRenderer_render_attributeEor, {attributeEor}
    .else
        ngin_mov8  __ngin_SpriteRenderer_render_attributeEor, #0
    .endif

    jsr __ngin_SpriteRenderer_render
.endmacro

.endif
