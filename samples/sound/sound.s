.include "ngin/ngin.inc"

; \todo More songs
; \todo Trigger sound effects with controller

; From asset importer:
.include "sounds.inc"

.segment "CODE"

ngin_entryPoint start
.proc start
    ; Enable NMI so that we can use ngin_Nmi_waitVBlank.
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    ngin_Muse_init #sounds
    ngin_Muse_startSong #sounds::songs::test_song

    ; Unpause the music.
    ; \todo Expose flags, or expose pause/etc as macros.
    ngin_Muse_setFlags #0

    kSoundEffectRate = 50
    ngin_bss counter: .byte 0
    ngin_mov8 counter, #kSoundEffectRate
    loop:
        dec counter
        ngin_branchIfNotZero counterNotZero
            ngin_mov8 counter, #kSoundEffectRate
            ngin_Lfsr8_random
            pha
            and #%1
            ngin_branchIfZero dontTrigger
                ngin_Muse_startEffect #sounds::effects::checkpoint, #0
            dontTrigger:

            pla
            and #%10
            ngin_branchIfZero dontTrigger2
                ngin_Muse_startEffect #sounds::effects::break, #1
            dontTrigger2:
        counterNotZero:

        ngin_Nmi_waitVBlank
        ngin_Muse_update
    jmp loop
.endproc
