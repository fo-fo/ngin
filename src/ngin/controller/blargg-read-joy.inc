.if .not .defined( NGIN_BLARGG_READ_JOY_INC_INCLUDED )
NGIN_BLARGG_READ_JOY_INC_INCLUDED = 1

; This file is based on read_joy.inc of read_joy3.zip from:
; http://forums.nesdev.com/viewtopic.php?f=2&t=4124
; The routines have been modified to template macros, so that they can be used
; to read both controllers.

.include "controller-common.inc"

; -----------------------------------------------------------------------------

; Reads controller into A and temp.
; Unreliable if DMC is playing.
; Preserved: X, Y
; Time: 153 clocks
.macro blargg_readJoyFast_template joystick
; \todo Report space wasted due to alignment.
.align 32
.ident( .sprintf( "blargg_readJoyFast%d", (joystick) ) ):
    ; Strobe controller
    lda #1                      ; 2
    sta $4016                   ; 4
    lda #0                      ; 2
    sta $4016                   ; 4

    ; Read 8 bits
    lda #$80                    ; 2
    sta __ngin_controllerTemp1  ; 3
:   lda $4016+joystick          ; *4

    ; Merge bits 0 and 1 into carry. Normal
    ; controllers use bit 0, and Famicom
    ; external controllers use bit 1.
    and #$03                    ; *2
    cmp #$01                    ; *2

    ror __ngin_controllerTemp1  ; *5
    bcc :-                      ; *3
                                ; -1
    lda __ngin_controllerTemp1  ; 3
    rts                         ; 6
.endmacro

; Reads controller into A.
; Reliable even if DMC is playing.
; Preserved: X, Y
; Time: ~660 clocks
.macro blargg_readJoy_template joystick
.ident( .sprintf( "blargg_readJoy%d", (joystick) ) ):
    .local readJoyFast
    readJoyFast := .ident( .sprintf( "blargg_readJoyFast%d", (joystick) ) )
    jsr readJoyFast
    sta __ngin_controllerTemp3
    jsr readJoyFast
    pha
    jsr readJoyFast
    sta __ngin_controllerTemp2
    jsr readJoyFast

    ; All combinations of one controller
    ; change and one DMC DMA corruption
    ; leave at least two matching readings,
    ; and never just the first and last
    ; matching. No more than one DMC DMA
    ; corruption can occur.

    ; X--X can't occur
    pla
    cmp __ngin_controllerTemp3
    beq :+                          ; XX--
    cmp __ngin_controllerTemp1
    beq :+                          ; -X-X

    lda __ngin_controllerTemp2      ; X-X-
                                    ; -XX-
                                    ; --XX
:   cmp #0
    rts
.endmacro

.endif
