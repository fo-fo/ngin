.include "ngin/ngin.inc"
.include "assets/maps.inc"

; -----------------------------------------------------------------------------

.segment "RODATA"

.proc spriteDefinition
    ngin_SpriteRenderer_metasprite
        ngin_SpriteRenderer_sprite 0, 0, objectTilesFirstIndex+0, %000_000_01
    ngin_SpriteRenderer_endMetasprite
.endproc

.proc spriteDefinition2
    ngin_SpriteRenderer_metasprite
        ngin_SpriteRenderer_sprite 0, 0, objectTilesFirstIndex+0, %000_000_10
    ngin_SpriteRenderer_endMetasprite
.endproc

; -----------------------------------------------------------------------------

.segment "CODE"

; \todo Use temporary local variables for this.
ngin_bss spritePosition: .tag ngin_Vector2_16

ngin_Object_declare object_ball
    position .tag ngin_Vector2_16
ngin_Object_endDeclare

ngin_Object_define object_ball
    .proc construct
        ngin_log debug, "object_ball.construct()"

        ngin_mov32 { ngin_Object_this position, x }, \
                     ngin_Object_constructorParameter position

        rts
    .endproc

    .proc update
        ; ngin_log debug, "object_ball.update()"

        ngin_Camera_worldToSpritePosition { ngin_Object_this position, x }, \
                                            spritePosition

        ; \note X may be trashed here.

        ngin_SpriteRenderer_render #spriteDefinition, spritePosition

        ; \note X may be trashed here.

        rts
    .endproc
ngin_Object_endDefine

ngin_Object_declare object_snake
    position .tag ngin_Vector2_16
ngin_Object_endDeclare

ngin_Object_define object_snake
    .proc construct
        ngin_log debug, "object_snake.construct()"

        ngin_mov32 { ngin_Object_this position, x }, \
                     ngin_Object_constructorParameter position

        rts
    .endproc

    .proc update
        ; ngin_log debug, "object_snake.update()"

        ngin_Camera_worldToSpritePosition { ngin_Object_this position, x }, \
                                            spritePosition

        ; \note X may be trashed here.

        ngin_SpriteRenderer_render #spriteDefinition2, spritePosition

        ; \note X may be trashed here.

        rts
    .endproc
ngin_Object_endDefine

; -----------------------------------------------------------------------------

ngin_entryPoint start
.proc start
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    jsr uploadPalette
    ; \todo This is redundant after proper reset code.
    jsr initializeNametable

    ; Load map and initialize the view in the nametable.
    ngin_MapData_load #maps_objectSpawner
    ngin_Camera_initializeView #maps_objectSpawner::markers::topLeft

    ; Re-enable NMI, because ngin_Camera_initializeView has disabled it.
    ; \todo Shadow registers to be able to track register state (so that
    ;       the function could avoid disabling NMI) (?)
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    loop:
        ngin_ShadowOam_startFrame
        ngin_Object_updateAll
        ngin_ShadowOam_endFrame
        ngin_waitVBlank
        ngin_mov8 ppu::oam::dma, #.hibyte( ngin_ShadowOam_buffer )
        ngin_MapScroller_ppuRegisters
        stx ppu::scroll
        sty ppu::scroll
        ora #ppu::ctrl::kGenerateVblankNmi
        sta ppu::ctrl
        ngin_mov8 ppu::mask, #( ppu::mask::kShowBackground     | \
                                ppu::mask::kShowBackgroundLeft | \
                                ppu::mask::kShowSprites        | \
                                ppu::mask::kShowSpritesLeft )
    jmp loop
.endproc

.proc uploadPalette
    ngin_waitVBlank

    ; Set all palettes to black.
    ngin_setPpuAddress #ppu::backgroundPalette
    ngin_fillPort #ppu::data, #$F, #32

    ngin_pushSeg "RODATA"
    .proc palette
        .byte $0F, $06, $16, $26
        .byte $0F, $09, $19, $29
        .byte $0F, $02, $12, $22
        .byte $0F, $04, $14, $24
    .endproc
    ngin_popSeg

    ngin_setPpuAddress #ppu::backgroundPalette
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )

    rts
.endproc

.proc initializeNametable
    ngin_setPpuAddress #ppu::nametable0
    ngin_fillPort #ppu::data, #0, #4*1024

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

objectTilesFirstIndex = .lobyte( */ppu::kBytesPer8x8Sprite )
    ngin_tile "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########"
