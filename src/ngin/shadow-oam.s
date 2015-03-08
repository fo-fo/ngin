.include "ngin/shadow-oam.inc"
.include "ngin/core.inc"
.include "ngin/branch.inc"
.include "ngin/ppu.inc"

kShadowOamSize = 256

.segment "NGIN_SHADOW_OAM"

ngin_shadowOam:         .res kShadowOamSize
.assert .lobyte( ngin_shadowOam ) = 0, error, \
        "ngin_shadowOam must be page aligned"

.segment "NGIN_BSS"

ngin_shadowOamPointer:  .byte 0

.segment "NGIN_CODE"

.proc __ngin_ShadowOam_startFrame
    ngin_mov8 ngin_shadowOamPointer, #0
    rts
.endproc

.proc __ngin_ShadowOam_endFrame
    ; If shadow OAM not full, hide the rest of the sprites.
    ; \todo Can use the pointer from previous frame to know the maximum amount
    ;       of sprites needed to hide (but remember OAM decay).
    ldx ngin_shadowOamPointer
    cpx #ngin_kShadowOamFull
    beq full
        ; Not full. Hide the rest of the sprites.
        lda #$FF

        loop:
            sta ngin_shadowOam + ppu::oam::Object::y_, x
            axs #.lobyte( -.sizeof( ppu::oam::Object ) )
        ngin_branchIfNotZero loop

        ; Set the full flag for consistency, even though it shouldn't be used
        ; after this function has been called.
        .assert ngin_kShadowOamFull = $FF, error
        sta ngin_shadowOamPointer
    full:
    rts
.endproc
