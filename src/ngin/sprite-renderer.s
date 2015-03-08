.include "ngin/sprite-renderer.inc"
.include "ngin/ppu.inc"
.include "ngin/shadow-oam.inc"
.include "ngin/arithmetic.inc"
.include "ngin/branch.inc"

; Sprite is visible if Y is in range 0..238 (Y=239 is not visible because of the
; one scanline delay in PPU's sprite handling).
kMaxVisibleY = 238

.segment "NGIN_ZEROPAGE" : zeropage

__ngin_SpriteRenderer_render_spriteDefinition:  .addr 0

.segment "NGIN_BSS"

__ngin_SpriteRenderer_render_position:          .tag ngin_Vector2_16

.segment "NGIN_CODE"

.proc __ngin_SpriteRenderer_render
    spriteDefinition := __ngin_SpriteRenderer_render_spriteDefinition
    position := __ngin_SpriteRenderer_render_position

    ; Load shadow OAM pointer.
    ldx ngin_shadowOamPointer

    ; Check if OAM is already full.
    cpx #ngin_kShadowOamFull
    beq oamFullOnEntry

    ldy #0
    loop:
        ; Read the attributes (also doubles as a possible terminator byte).
        lda ( spriteDefinition ), y

        ; Terminator must be zero or this fails (need to add cmp in that case).
        .assert ngin_kSpriteDefinitionTerminator = 0, error
        ngin_branchIfZero endOfSpriteDefinition

        ; Store the attributes. The value might go unused since we haven't
        ; clipped yet, but no harm done because we know there's space.
        sta ngin_shadowOam + ppu::oam::Object::attributes, x

        ; \todo X and Y handling is almost identical, might want to macroify.

        ; ---------------------------------------------------------------------
        ; X coordinate handling

        ; Read the X coordinate.
        iny
        lda ( spriteDefinition ), y
        ; Move to the Y coordinate.
        iny

        ; Add to the position.
        clc
        adc position + ngin_Vector2_16::x_ + 0
        ; Save result directly to OAM, because we can.
        sta ngin_shadowOam + ppu::oam::Object::x_, x

        ; Add the hibyte of the origin of position, so that a position of
        ; $8000 will result in the hibyte wrapping to 0, which we'll use to
        ; find out whether the sprite is in range. All of this assumes that
        ; the unsigned position origin is $8000.
        lda position + ngin_Vector2_16::x_ + 1
        .assert ngin_kSpriteRendererOriginX = $8000, error
        adc #.hibyte( ngin_kSpriteRendererOriginX )
        ; If hibyte of X is 0, X is in range 0..255, so sprite is visible.
        ngin_branchIfNotZero notVisibleX

        ; If we're here, sprite is visible in the X direction.
        ; \note If the 8-pixel column on the left side is hidden, then
        ;       sprites with X=0 could be clipped, but it's too rare and
        ;       adds too much complexity to special-case here.

        ; ---------------------------------------------------------------------
        ; Y coordinate handling

        ; Read the Y coordinate.
        lda ( spriteDefinition), y
        ; Move to the tile.
        iny

        ; Add to the position.
        clc
        adc position + ngin_Vector2_16::y_ + 0
        sta ngin_shadowOam + ppu::oam::Object::y_, x

        lda position + ngin_Vector2_16::y_ + 1
        .assert ngin_kSpriteRendererOriginY = $8000, error
        adc #.hibyte( ngin_kSpriteRendererOriginY )
        ; If hibyte of Y is 0, Y is in range 0..255, so sprite *might* be
        ; visible.
        ngin_branchIfNotZero notVisibleY
            ; Might be visible, check if in range 0..kMaxVisibleY.
            ngin_cmp8 { ngin_shadowOam + ppu::oam::Object::y_, x }, \
                      #kMaxVisibleY+1
            ngin_branchIfGreaterOrEqual notVisibleY

            ; Sprite is visible, display it.
            ; Read the tile and store to OAM.
            ngin_mov8 { ngin_shadowOam + ppu::oam::Object::tile, x }, \
                      { ( spriteDefinition ), y }

            ; Move to the next sprite in sprite definition.
            iny

            ; Move to the next sprite in OAM.
            txa
            axs #.lobyte( -.sizeof( ppu::oam::Object ) )

            ; If X wrapped around to 0, the OAM is full.
            ngin_branchIfZero oamFull

            jmp loop
        notVisibleX:
        ; Move to the tile.
        iny

        notVisibleY:
        ; Move to the next sprite in sprite definition.
        iny
    jmp loop

    rts

oamFull:
    ; OAM is full. Set the OAM pointer to a magic value to indicate that.
    ldx #ngin_kShadowOamFull

endOfSpriteDefinition:
    ; End of sprite definition reached.
    stx ngin_shadowOamPointer

oamFullOnEntry:
    rts
.endproc
