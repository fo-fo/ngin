.include "ngin/ngin.inc"

.include "assets/maps.inc"

.segment "BSS"

controller: .byte 0

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    jsr uploadPalette
    jsr uploadNametable

    ngin_MapData_load #maps_level1
    ngin_Camera_initializeView #maps_level1::markers::topLeft

    jsr interactiveTest

    jmp *
.endproc

.proc interactiveTest
    ; Enable NMI so that we can use ngin_waitVBlank.
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kGenerateVblankNmi

    loop:
        ngin_PpuBuffer_startFrame
        jsr readController
        jsr interactiveLogic
        ngin_PpuBuffer_endFrame

        ngin_waitVBlank
        ngin_PpuBuffer_upload
        ngin_MapScroller_ppuRegisters
        stx ppu::scroll
        sty ppu::scroll
        ora #ppu::ctrl::kGenerateVblankNmi
        sta ppu::ctrl
        ngin_mov8 ppu::mask, #( ppu::mask::kShowBackground | \
                                ppu::mask::kShowBackgroundLeft )
    jmp loop
.endproc

.proc readController
    ngin_Controller_read1
    sta controller

    rts
.endproc

.proc interactiveLogic
    ; Scroll the map based on controller input. Currently can only scroll
    ; one pixel at a time.
    ngin_bss deltaX: .byte 0
    ngin_bss deltaY: .byte 0

    ngin_mov8 deltaX, #0
    ngin_mov8 deltaY, #0

    lda controller
    and #ngin_Controller::kLeft
    ngin_branchIfZero notLeft
        ngin_mov8 deltaX, #ngin_signedByte -1
    notLeft:

    lda controller
    and #ngin_Controller::kRight
    ngin_branchIfZero notRight
        ngin_mov8 deltaX, #ngin_signedByte 1
    notRight:

    lda controller
    and #ngin_Controller::kUp
    ngin_branchIfZero notUp
        ngin_mov8 deltaY, #ngin_signedByte -1
    notUp:

    lda controller
    and #ngin_Controller::kDown
    ngin_branchIfZero notDown
        ngin_mov8 deltaY, #ngin_signedByte 1
    notDown:

    ngin_Camera_move deltaX, deltaY

out:
    rts
.endproc

.proc uploadPalette
    ngin_pollVBlank

    ; Set all palettes to black.
    ngin_setPpuAddress #ppu::backgroundPalette
    ngin_fillPort #ppu::data, #$F, #32

    .pushseg
    .segment "RODATA"
    .proc palette
        .byte $0F, $06, $16, $26
        .byte $0F, $09, $19, $29
        .byte $0F, $02, $12, $22
        .byte $0F, $04, $14, $24
    .endproc
    .popseg
    ngin_setPpuAddress #ppu::backgroundPalette
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )

    rts
.endproc

.proc uploadNametable
    ngin_setPpuAddress #ppu::nametable0
    ngin_fillPort #ppu::data, #0, #4*1024

    rts
.endproc
