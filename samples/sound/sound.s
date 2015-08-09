; Press A/B/Up/Right to play different songs and sound effects.

.include "ngin/ngin.inc"

; From asset importer:
.include "sounds.inc"

.segment "CODE"

ngin_entryPoint start
.proc start
    ; Enable NMI so that we can use ngin_Nmi_waitVBlank.
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    ngin_Muse_init #sounds
    ngin_Muse_startSong #sounds::songs::ninja_song

    ; Unpause the music.
    ; \todo Expose flags, or expose pause/etc as macros.
    ngin_Muse_setFlags #0

    loop:
        ngin_bss previousController: .byte 0
        ngin_mov8 previousController, controller
        ngin_Controller_read1
        ngin_bss controller: .byte 0
        sta controller

        lda previousController
        eor #$FF
        and controller
        ngin_bss newController: .byte 0
        sta newController

        lda newController
        and #ngin_Controller::kA
        ngin_branchIfZero notA
            ngin_Muse_startSong #sounds::songs::ninja_song
        notA:

        lda newController
        and #ngin_Controller::kB
        ngin_branchIfZero notB
            ngin_Muse_startSong #sounds::songs::castle_song
        notB:

        lda newController
        and #ngin_Controller::kRight
        ngin_branchIfZero notRight
            ngin_Muse_startEffect #sounds::effects::checkpoint, #0
        notRight:

        lda newController
        and #ngin_Controller::kUp
        ngin_branchIfZero notUp
            ngin_Muse_startEffect #sounds::effects::break, #1
        notUp:

        ngin_Nmi_waitVBlank
        ngin_Muse_update
    jmp loop
.endproc
