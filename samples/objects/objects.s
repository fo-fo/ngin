.include "ngin/ngin.inc"
.include "assets/maps.inc"
.include "object-ball.inc"

ngin_bss spawnCounter: .byte 0

kSpawnInterval = 60 ; frames

.segment "CODE"

ngin_entryPoint start
.proc start
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    jsr uploadPalette
    ; \todo This is redundant after proper reset code.
    jsr initializeNametable

    ngin_mov8 spawnCounter, #kSpawnInterval-30

    ; Load map and initialize the view in the nametable.
    ngin_MapData_load #maps_objects
    ngin_Camera_initializeView #maps_objects::markers::topLeft

    ; Re-enable NMI, because ngin_Camera_initializeView has disabled it.
    ; \todo Shadow registers to be able to track register state (so that
    ;       the function could avoid disabling NMI) (?)
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    loop:
        jsr spawnObjects
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

.proc spawnObjects
    ; Spawn new objects at the specified interval.

    inc spawnCounter
    lda spawnCounter
    cmp #kSpawnInterval
    bne noSpawn
        ngin_mov8 spawnCounter, #0
        jsr spawn
    noSpawn:

    rts
.endproc

.proc spawn
    ngin_bss randomDiv2: .byte 0

    .macro randomSpawnPosition destination, offset
        ngin_Lfsr8_random
        lsr
        clc
        adc #64
        sta randomDiv2
        ; \todo Add 3-param support to ngin_add16_8 (or a way to specify a byte
        ;       param to ngin_add16...)
        ngin_mov16 {destination}, {offset}
        ngin_add16_8 {destination}, randomDiv2
    .endmacro

    ; Generate a random spawn position and set it in the constructor
    ; parameters.

    randomSpawnPosition \
        ngin_Object_constructorParameter position + ngin_Vector2_16::x_, \
        #ngin_Vector2_16_immediateX maps_objects::markers::topLeft

    randomSpawnPosition \
        ngin_Object_constructorParameter position + ngin_Vector2_16::y_, \
        #ngin_Vector2_16_immediateY maps_objects::markers::topLeft

    ; Create the object instance.
    ngin_Object_new #object_ball

    ; Check if allocation succeeded.
    cpx #ngin_Object_kInvalidId
    bne notInvalid
        ngin_log debug, "couldn't allocate object"
        nop
    notInvalid:

    rts
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
