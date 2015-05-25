.include "ngin/ngin.inc"
.include "assets/maps.inc"

; -----------------------------------------------------------------------------

.segment "RODATA"

.proc metasprite
    ngin_SpriteRenderer_metasprite
        ngin_SpriteRenderer_sprite 0, 0, objectTilesFirstIndex+0, %000_000_01
    ngin_SpriteRenderer_endMetasprite
.endproc

.proc metasprite2
    ngin_SpriteRenderer_metasprite
        ngin_SpriteRenderer_sprite 0, 0, objectTilesFirstIndex+0, %000_000_10
    ngin_SpriteRenderer_endMetasprite
.endproc

; -----------------------------------------------------------------------------

.segment "CODE"

; \todo Use temporary local variables for this.
ngin_bss spritePosition: .tag ngin_Vector2_16

ngin_Object_declare object_ball
    position .tag ngin_Vector2_16_8
ngin_Object_endDeclare

ngin_Object_define object_ball
    .proc onConstruct
        ngin_log debug, "object_ball.construct()"

        ; Initialize position from constructor parameters. Have to set X and Y
        ; separately because the integer parts are not contiguous in memory.
        ngin_mov16 { ngin_Object_this position+ngin_Vector2_16_8::intX, x }, \
            ngin_Object_constructorParameter position+ngin_Vector2_16::x_
        ngin_mov16 { ngin_Object_this position+ngin_Vector2_16_8::intY, x }, \
            ngin_Object_constructorParameter position+ngin_Vector2_16::y_

        ; Set the fractional part to 0.
        ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracX, x }, #0
        ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracY, x }, #0

        rts
    .endproc

    .proc onRender
        ngin_Camera_worldToSpritePosition { ngin_Object_this position, x }, \
                                            spritePosition

        ; \note X may be trashed here.

        ngin_SpriteRenderer_render #metasprite, spritePosition

        ; \note X may be trashed here.

        rts
    .endproc

    .proc onUpdate
        ; ngin_log debug, "object_ball.update()"
        rts
    .endproc
ngin_Object_endDefine

ngin_Object_declare object_snake
    position .tag ngin_Vector2_16_8
ngin_Object_endDeclare

ngin_Object_define object_snake
    .proc onConstruct
        ngin_log debug, "object_snake.construct()"

        ; Initialize position from constructor parameters. Have to set X and Y
        ; separately because the integer parts are not contiguous in memory.
        ngin_mov16 { ngin_Object_this position+ngin_Vector2_16_8::intX, x }, \
            ngin_Object_constructorParameter position+ngin_Vector2_16::x_
        ngin_mov16 { ngin_Object_this position+ngin_Vector2_16_8::intY, x }, \
            ngin_Object_constructorParameter position+ngin_Vector2_16::y_

        ; Set the fractional part to 0.
        ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracX, x }, #0
        ngin_mov8 { ngin_Object_this position+ngin_Vector2_16_8::fracY, x }, #0

        rts
    .endproc

    .proc onRender
        ngin_Camera_worldToSpritePosition { ngin_Object_this position, x }, \
                                            spritePosition

        ; \note X may be trashed here.

        ngin_SpriteRenderer_render #metasprite2, spritePosition

        ; \note X may be trashed here.

        rts
    .endproc

    .proc onUpdate
        ; ngin_log debug, "object_snake.update()"
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

        ngin_Nmi_waitVBlank
        ngin_ShadowOam_upload
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
    ngin_Nmi_waitVBlank

    ; Set all palettes to black.
    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_fillPort #ppu::data, #$F, #32

    ngin_pushSeg "RODATA"
    .proc palette
        .byte $0F, $06, $16, $26
        .byte $0F, $09, $19, $29
        .byte $0F, $02, $12, $22
        .byte $0F, $04, $14, $24
    .endproc
    ngin_popSeg

    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )

    rts
.endproc

.proc initializeNametable
    ngin_Ppu_setAddress #ppu::nametable0
    ngin_fillPort #ppu::data, #0, #4*1024

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

objectTilesFirstIndex = .lobyte( */ppu::kBytesPer8x8Tile )
    ngin_tile "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########"
