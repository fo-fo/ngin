.include "ngin/ppu-buffer.inc"
.include "ngin/core.inc"
.include "ngin/branch.inc"
.include "ngin/ppu.inc"

; \todo Should be configurable somewhere
kPpuBufferSize = 64

.segment "STACK"

ngin_ppuBuffer: .res kPpuBufferSize
.assert .hibyte( ngin_ppuBuffer ) = 1 .and \
        .sizeof( ngin_ppuBuffer ) > 0 .and \
        .hibyte( ngin_ppuBuffer + .sizeof( ngin_ppuBuffer )-1 ) = 1, \
        error

.segment "BSS"

ngin_ppuBufferPointer: .byte 0

.segment "CODE"

.proc __ngin_PpuBuffer_startFrame
    ; Start filling the buffer from the beginning.
    ngin_mov8 ngin_ppuBufferPointer, #0
    ngin_mov8 ngin_ppuBuffer, #ngin_kPpuBufferTerminatorMask
    rts
.endproc

.proc __ngin_PpuBuffer_upload
    .pushseg
    .segment "BSS"
        savedStackPointer: .byte 0
    .popseg

    ; \todo Runtime assert for ngin_ppuBufferPointer overflows.

    ; Save stack pointer.
    tsx
    stx savedStackPointer

    ; Point stack pointer to the beginning of the PPU buffer.
    ; Need to subtract one because PLA increments before fetching.
    ldx #.lobyte( ngin_ppuBuffer - 1 )
    txs

    ; Clear the ppu::addr even/odd write flag, and acknowledge the NMI.
    bit ppu::status

    jmp startLoop

    loop:
        ; Save the hibyte in X.
        tax

        ; \note ppu::ctrl has to be written before ppu::addr, because it would
        ;       otherwise trash the address.
        ; AND with the mask. If zero, can use as ppu::ctrl as is. Otherwise,
        ; set the kAddressIncrement32 flag in ppu::ctrl.
        and #ngin_kPpuBufferIncrease32Mask
        ngin_branchIfZero increase1
            ; Increase 32
            lda #ppu::ctrl::kAddressIncrement32
        increase1:
        sta ppu::ctrl

        ; \note PPU address space is only 14 bits, so the top two bits that
        ;       are used for flags are automatically ignored.
        stx ppu::addr

        ; Get the lobyte of PPU address.
        pla
        sta ppu::addr

        ; Get the number of bytes.
        pla
        tax

        ; Copy data.
        ; \todo Unroll the loop a bit.
        copyData:
            pla
            sta ppu::data
            dex
        ngin_branchIfNotZero copyData

        startLoop:
        ; Get the hibyte of PPU address from buffer.
        pla
    ; If top bit is set, exit loop.
    .assert ngin_kPpuBufferTerminatorMask = %1000_0000, error
    bpl loop

loopDone:

    ; \todo Mark the buffer as processed (terminator in the beginning)?

    ; Restore stack pointer.
    ldx savedStackPointer
    txs

    rts
.endproc
