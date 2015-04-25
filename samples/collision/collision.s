.include "ngin/ngin.inc"

.segment "RODATA"

; \todo Make it possible to use different sizes for the sprites.
kMetaspriteWidth  = 16
kMetaspriteHeight = 24

.macro defineMetasprite tile
    .byte ngin_SpriteRenderer_kAttribute|%000_000_00 ; Attributes
    .byte ngin_SpriteRenderer_kAdjustX+0             ; X
    .byte ngin_SpriteRenderer_kAdjustY+0             ; Y
    .byte tile                                      ; Tile

    .byte ngin_SpriteRenderer_kAttribute|%000_000_00 ; Attributes
    .byte ngin_SpriteRenderer_kAdjustX+8             ; X
    .byte ngin_SpriteRenderer_kAdjustY+0             ; Y
    .byte tile                                      ; Tile

    .byte ngin_SpriteRenderer_kAttribute|%000_000_00 ; Attributes
    .byte ngin_SpriteRenderer_kAdjustX+0             ; X
    .byte ngin_SpriteRenderer_kAdjustY+8             ; Y
    .byte tile                                      ; Tile

    .byte ngin_SpriteRenderer_kAttribute|%000_000_00 ; Attributes
    .byte ngin_SpriteRenderer_kAdjustX+8             ; X
    .byte ngin_SpriteRenderer_kAdjustY+8             ; Y
    .byte tile                                      ; Tile

    .byte ngin_SpriteRenderer_kAttribute|%000_000_00 ; Attributes
    .byte ngin_SpriteRenderer_kAdjustX+0             ; X
    .byte ngin_SpriteRenderer_kAdjustY+16            ; Y
    .byte tile                                      ; Tile

    .byte ngin_SpriteRenderer_kAttribute|%000_000_00 ; Attributes
    .byte ngin_SpriteRenderer_kAdjustX+8             ; X
    .byte ngin_SpriteRenderer_kAdjustY+16            ; Y
    .byte tile                                      ; Tile

    .byte ngin_SpriteRenderer_kDefinitionTerminator
.endmacro

.proc spriteDefinition0
    defineMetasprite 1
.endproc

.proc spriteDefinition1
    defineMetasprite 2
.endproc

.define controllerDeltaX_ 0,  0, 0, -1, 1
.define controllerDeltaY_ 0, -1, 1,  0, 0

.scope controllerDeltaX
    lo: .lobytes controllerDeltaX_
    hi: .hibytes controllerDeltaX_
.endscope

.scope controllerDeltaY
    lo: .lobytes controllerDeltaY_
    hi: .hibytes controllerDeltaY_
.endscope

.segment "BSS"

kNumControllers = 2
controllers:                .res kNumControllers
controllersPrevious:        .res kNumControllers
controllersNewlyPressed:    .res kNumControllers

positions:                  .tag ngin_Vector2_16
                            .tag ngin_Vector2_16
bottomRightPositions:       .tag ngin_Vector2_16
                            .tag ngin_Vector2_16

collisionActive:            .byte 0
frameCount:                 .byte 0

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    jsr initialize
    jsr uploadPalette

    loop:
        jsr readControllers
        jsr moveSprites
        jsr checkCollisions
        jsr renderSprites

        ngin_pollVBlank
        ngin_mov8 ppu::oam::dma, #.hibyte( ngin_ShadowOam_buffer )
        ngin_mov8 ppu::mask, #( ppu::mask::kShowSprites | \
                                ppu::mask::kShowSpritesLeft )

        inc frameCount
    jmp loop
.endproc

.proc initialize
    kSpriteOrigin0 = ngin_immediateVector2_16 \
        ngin_SpriteRenderer_kOriginX, ngin_SpriteRenderer_kOriginY
    kSpriteOrigin1 = ngin_immediateVector2_16 \
        ngin_SpriteRenderer_kOriginX+24, ngin_SpriteRenderer_kOriginY+24

    ngin_mov32 positions + 0 * .sizeof( ngin_Vector2_16 ), #kSpriteOrigin0
    ngin_mov32 positions + 1 * .sizeof( ngin_Vector2_16 ), #kSpriteOrigin1

    rts
.endproc

.proc uploadPalette
    ngin_pollVBlank

    ; Set all palettes to black.
    ngin_setPpuAddress #ppu::backgroundPalette
    ngin_fillPort #ppu::data, #$F, #32

    ; Set some sprite colors.
    ngin_setPpuAddress #ppu::spritePalette+2
    ngin_mov8 ppu::data, #$10
    ngin_mov8 ppu::data, #$30

    rts
.endproc

.proc readControllers
    .repeat ::kNumControllers, i
        ngin_mov8 controllersPrevious+i, controllers+i
    .endrepeat

    ngin_Controller_read1
    sta controllers+0
    ngin_Controller_read2
    sta controllers+1

    ; Find 0->1 transitions of buttons. Previous must be 0, current must be 1.
    .repeat ::kNumControllers, i
        lda controllersPrevious+i
        eor #$FF
        and controllers+i
        sta controllersNewlyPressed+i
    .endrepeat

    rts
.endproc

.proc moveSprites
    .repeat ::kNumControllers, i
    .scope
        lda controllersNewlyPressed+i

        ; Check the top 4 most significant bits, set X to 0..4 based on which
        ; one is set. X is 0 if none are set.
        ; The top 4 most significant bits correspond to right, left, down, up.
        ldx #4
        more:
            asl
            bcs found1
            dex
        ngin_branchIfNotZero more
        found1:

        position := positions + i*.sizeof( ngin_Vector2_16 )

        ; Add delta to X.
        ; \todo Add a macro for 16-bit add (need support for hibyte offset).
        lda position + ngin_Vector2_16::x_
        clc
        adc controllerDeltaX::lo, x
        sta position + ngin_Vector2_16::x_
        lda position + ngin_Vector2_16::x_+1
        adc controllerDeltaX::hi, x
        sta position + ngin_Vector2_16::x_+1

        ; Add delta to Y.
        lda position + ngin_Vector2_16::y_
        clc
        adc controllerDeltaY::lo, x
        sta position + ngin_Vector2_16::y_
        lda position + ngin_Vector2_16::y_+1
        adc controllerDeltaY::hi, x
        sta position + ngin_Vector2_16::y_+1
    .endscope
    .endrepeat

    rts
.endproc

.proc checkCollisions
    .repeat ::kNumControllers, i
    .scope
        ; Calculate bottom right coordinates by adding size to the top left
        ; coordinates.
        ; \todo Needless copy of the result is made -- could output directly to
        ;       the rectOverlap parameter space.
        position := positions + i*.sizeof( ngin_Vector2_16 )
        bottomRightPosition := bottomRightPositions + \
                               i*.sizeof( ngin_Vector2_16 )
        ngin_add16 bottomRightPosition + ngin_Vector2_16::x_, \
                   position + ngin_Vector2_16::x_, \
                   #kMetaspriteWidth
        ngin_add16 bottomRightPosition + ngin_Vector2_16::y_, \
                   position + ngin_Vector2_16::y_, \
                   #kMetaspriteHeight
    .endscope
    .endrepeat

    ; Check for rect-rect collision.
    ngin_Collision_rectOverlap \
        positions + 0*.sizeof( ngin_Vector2_16 ), \
        bottomRightPositions + 0*.sizeof( ngin_Vector2_16 ), \
        positions + 1*.sizeof( ngin_Vector2_16 ), \
        bottomRightPositions + 1*.sizeof( ngin_Vector2_16 )
    ; Capture the return value from carry to MSB of A.
    lda #0
    ror
    sta collisionActive

    rts
.endproc

.proc renderSprites
    ngin_ShadowOam_startFrame

    ; Flicker the sprite if there's a collision.
    lda collisionActive
    bpl notActive
        ; Collision is active. Don't draw every now and then depending on timer.
        lda frameCount
        and #%10
        ngin_branchIfZero dontDrawFirst
    notActive:
    ngin_SpriteRenderer_render \
        #spriteDefinition0, positions + 0*.sizeof( ngin_Vector2_16 )
    dontDrawFirst:

    ngin_SpriteRenderer_render \
        #spriteDefinition1, positions + 1*.sizeof( ngin_Vector2_16 )

    ngin_ShadowOam_endFrame

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

.repeat 16
    .byte 0
.endrepeat

.repeat 16
    .byte $FF
.endrepeat

.repeat 8
    .byte $00
.endrepeat
.repeat 8
    .byte $FF
.endrepeat
