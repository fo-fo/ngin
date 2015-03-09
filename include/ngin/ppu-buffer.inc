.if .not .defined( NGIN_PPU_BUFFER_INC_INCLUDED )
NGIN_PPU_BUFFER_INC_INCLUDED = 1

.include "ngin/core.inc"

; This bit has to be set in a terminating byte of a PPU buffer.
ngin_kPpuBufferTerminatorMask = %1000_0000

; This bit has to be set in hibyte of ppuAddress of ngin_PpuBufferElement for
; PPU address to be increased by 32 for each data byte. Otherwise increase is 1.
ngin_kPpuBufferIncrease32Mask = %0100_0000

.struct ngin_PpuBufferElement
    ; PPU address, big endian
    ppuAddress  .dbyt

    ; Size of "data". 0 means 256 bytes.
    size        .byte

    ; Data comprises of "size" bytes.
    data        .tag __ngin_EmptyStruct
.endstruct

; PPU buffer
.global ngin_ppuBuffer

; Index to the first usable byte within ngin_ppuBuffer.
.global ngin_ppuBufferPointer

.global __ngin_PpuBuffer_startFrame
.macro ngin_PpuBuffer_startFrame
    jsr __ngin_PpuBuffer_startFrame
.endmacro

.macro ngin_PpuBuffer_endFrame
    ; Currently no-op
.endmacro

.global __ngin_PpuBuffer_upload
.macro ngin_PpuBuffer_upload
    jsr __ngin_PpuBuffer_upload
.endmacro

.endif
