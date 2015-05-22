.include "ngin/ngin.inc"
.include "assets/maps/maps.inc"
.include "object-player.inc"

.segment "CODE"

ngin_entryPoint start
.proc start
    ngin_Debug_uploadDebugPalette

    ngin_MapData_load #maps_level1
    ngin_Camera_initializeView #maps_level1::markers::camera

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

    ngin_Object_updateAll

    ngin_PpuBuffer_endFrame
    ngin_ShadowOam_endFrame

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

    ldx playerId
    ngin_bss vector: .word 0
    ngin_bss movementX: .byte 0
    ngin_bss movementY: .byte 0

    kMaxScroll = 8

    ; Macro to take care of camera movement in horizontal/vertical direction.
    ; "component" has to be x_ or y_.
    .macro moveCamera_template component, outputVariable
        ; Calculate vector from camera to the player (signed result).
        ngin_sub16 vector, \
                 { playerThis position+ngin_Vector2_16::component, x }, \
                   ngin_Camera_position+ngin_Vector2_16::component

        ; Additional offset to center the view (somewhat).
        ; \todo Something better.
        ngin_add16 vector, #ngin_signedWord -128

        ; Default to 0.
        ngin_mov8 outputVariable, #0

        ; Clamp to the maximum scroll speed. First test for zero.
        lda vector+0
        ora vector+1
        ngin_branchIfZero skip
            ; Not zero, copy the sign only (for now) and move the camera
            ; depending on it.
            bit vector+1
            bpl positive
                ; Negative
                ; \note A is destroyed by ngin_cmp16, so use Y.
                ldy vector+0
                ; If less than -8, clamp. Unsigned comparison works fine here
                ; because we know "vector" is negative.
                ngin_cmp16 vector, #ngin_signedWord -kMaxScroll
                ngin_branchIfGreaterOrEqual noClampNegative
                    ldy #ngin_signedByte -kMaxScroll
                .local noClampNegative
                noClampNegative:
                jmp doneNegative
            .local positive
            positive:
                ; Positive
                ldy vector+0
                ; If over 8, clamp.
                ngin_cmp16 vector, #ngin_signedWord kMaxScroll
                ngin_branchIfLess noClampPositive
                    ldy #ngin_signedByte kMaxScroll
                .local noClampPositive
                noClampPositive:
            .local doneNegative
            doneNegative:
            sty outputVariable
        .local skip
        skip:
    .endmacro

    moveCamera_template x_, movementX
    moveCamera_template y_, movementY

    ngin_Camera_move movementX, movementY

    .undefine playerThis

    rts
.endproc
