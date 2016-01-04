.include "ngin/ngin.inc"
.include "assets/maps/maps.inc"
.include "object-player.inc"

.segment "CODE"

ngin_entryPoint start
.proc start
    ngin_Debug_uploadDebugPalette
    jsr uploadPalette

    ngin_MapData_load #maps_vilenes
    ngin_Camera_initializeView #maps_vilenes::markers::camera

    ; Enable NMI so that we can use ngin_Nmi_waitVBlank.
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    loop:
        jsr update

        ngin_Nmi_waitVBlank
        ngin_ShadowOam_upload
        ngin_PpuBuffer_upload
        ngin_MapScroller_ppuRegisters
        stx ppu::scroll
        sty ppu::scroll
        ora #( ppu::ctrl::kGenerateVblankNmi | \
               ppu::ctrl::kSpriteSize8x16 )
        sta ppu::ctrl
        ngin_mov8 ppu::mask, #( ppu::mask::kShowBackground     | \
                                ppu::mask::kShowBackgroundLeft | \
                                ppu::mask::kShowSprites        | \
                                ppu::mask::kShowSpritesLeft )
    jmp loop
.endproc

.proc update
    ngin_ShadowOam_startFrame
    ngin_PpuBuffer_startFrame

    ; \note Camera should be moved before any of the objects are processed,
    ;       so that the objects can use the correct camera position for their
    ;       rendering. Also it should not be moved after object processing,
    ;       because then the sprites would be off-sync with background.
    jsr moveCamera

    ; Update player manually (calls onManualUpdate) so that it will be updated
    ; before all other objects.
    ngin_Object_manualUpdate object_Player, player_id

    ngin_Object_updateAll

    ngin_PpuBuffer_endFrame
    ngin_ShadowOam_endFrame

    rts
.endproc

.proc uploadPalette
    ngin_Ppu_pollVBlank

    .pushseg
    .segment "RODATA"
    .proc palette ; surt's village mockup:
        .byte $0F, 1, 18, 33
        .byte $0F, 0, 61, 48
        .byte $0F, 22, 39, 42
        .byte $0F, $04, $14, $24
    .endproc
    .popseg
    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )

    rts
.endproc

.proc moveCamera
    ; Calculate the desired camera position based on the player position.

    ; \todo Might want to offer this in the engine, e.g. something like
    ;       ngin_Camera_followObject (maybe some different behaviors for
    ;       follow, as well). Or, it could be just matter of setting a
    ;       "desired" position for Camera, then calling some update routine
    ;       to let it update itself.

    ; \todo playerId is not initialized anywhere (except the object constructor),
    ;       so we're relying on player object to exist at this point (could do
    ;       a runtime assert to make sure the object type matches...)

    .define playerThis( elem ) ngin_Object_other object_Player, {elem}

    ldx player_id

    ; \todo Use temporaries.
    ngin_bss cameraToPlayer:    .tag ngin_FixedPoint16_8
    ; Camera movement amount
    ngin_bss movementX:         .tag ngin_FixedPoint8_8
    ngin_bss movementY:         .tag ngin_FixedPoint8_8

    ; Macro to take care of camera movement in horizontal/vertical direction.
    ; "component" has to be x_ or y_.
    .macro moveCamera_template component, outputVariable
        ; Calculate vector from camera to the player (signed result).
        ; \todo Lowest 16 bits would be enough, because we can't handle
        ;       scroll speeds over 8 bits anyways (just make sure the
        ;       additional offset down below works alright)
        ngin_sub24 cameraToPlayer, \
                 { playerThis position+ngin_Vector2_16_8::component, x }, \
                   ngin_Camera_position+ngin_Vector2_16_8::component

        ; Additional offset to center the view (somewhat).
        ; \todo Something better.
        .if .xmatch( {component}, {x_} )
            ngin_add24 cameraToPlayer, #ngin_immFixedPoint16_8 ngin_signed16 -128, 0
        .else
            ngin_add24 cameraToPlayer, #ngin_immFixedPoint16_8 ngin_signed16 -192, 0
        .endif

        ; By default, assume that the 16.8 value fits in 8.8. If it doesn't,
        ; it will be clamped by the code below.
        ngin_mov16 outputVariable, cameraToPlayer

        ; Clamp to byte range. Check the sign so that we can use unsigned
        ; comparison. The exact amount we clamp to doesn't matter much, because
        ; Camera can't scroll much over 8 pixels per frame anyways.
        bit cameraToPlayer+2
        bpl positive
            ; Negative
            ngin_cmp24 cameraToPlayer, #ngin_immFixedPoint16_8 ngin_signed16 -128, 0
            ngin_branchIfGreaterOrEqual noClampNegative
                ngin_mov16 outputVariable, #ngin_immFixedPoint8_8 -128, 0
            .local noClampNegative
            noClampNegative:
            jmp doneNegative
        .local positive
        positive:
            ; Positive
            ngin_cmp24 cameraToPlayer, #ngin_immFixedPoint16_8 ngin_signed16 127, 0
            ngin_branchIfLess noClampPositive
                ngin_mov16 outputVariable, #ngin_immFixedPoint8_8 127, 0
            .local noClampPositive
            noClampPositive:
        .local doneNegative
        doneNegative:
    .endmacro

    moveCamera_template x_, movementX
    moveCamera_template y_, movementY

    ngin_Camera_move movementX, movementY

    .undefine playerThis

    rts
.endproc
