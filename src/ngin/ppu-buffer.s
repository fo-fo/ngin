.include "ngin/ppu-buffer.inc"
.include "ngin/core.inc"
.include "ngin/branch.inc"
.include "ngin/ppu.inc"
.include "ngin/assert.inc"

.segment "NGIN_STACK"

ngin_PpuBuffer_buffer: .res ngin_PpuBuffer_kBufferSize
.assert .hibyte( ngin_PpuBuffer_buffer ) = 1 .and \
        .sizeof( ngin_PpuBuffer_buffer ) > 0 .and \
        .hibyte( ngin_PpuBuffer_buffer + .sizeof( ngin_PpuBuffer_buffer )-1 ) = 1, \
        error

.segment "NGIN_BSS"

ngin_PpuBuffer_pointer: .byte 0

.segment "NGIN_CODE"

.proc __ngin_PpuBuffer_startFrame
    ; Start filling the buffer from the beginning.
    ngin_mov8 ngin_PpuBuffer_pointer, #0
    ngin_mov8 ngin_PpuBuffer_buffer, #ngin_PpuBuffer_kTerminatorMask
    rts
.endproc

.proc __ngin_PpuBuffer_upload
    __ngin_bss savedStackPointer: .byte 0

    ; Watch out for ngin_ppuBufferPointer overflows.
    ngin_assert .sprintf( "RAM.ngin_PpuBuffer_pointer < %d", \
                          ::ngin_PpuBuffer_kBufferSize )

    ; Save stack pointer.
    tsx
    stx savedStackPointer

    ; Point stack pointer to the beginning of the PPU buffer.
    ; Need to subtract one because PLA increments before fetching.
    ldx #.lobyte( ngin_PpuBuffer_buffer - 1 )
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
        and #ngin_PpuBuffer_kIncrease32Mask
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
    .assert ngin_PpuBuffer_kTerminatorMask = %1000_0000, error
    bpl loop

loopDone:

    ; \todo Mark the buffer as processed (terminator in the beginning)?
    ;       Or assert with Lua that the same buffer is not uploaded twice.

    ; Restore stack pointer.
    ldx savedStackPointer
    txs

    rts
.endproc
