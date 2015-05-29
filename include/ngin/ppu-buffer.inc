.if .not .defined( NGIN_PPU_BUFFER_INC_INCLUDED )
NGIN_PPU_BUFFER_INC_INCLUDED = 1

.include "ngin/core.inc"

; \todo Should be configurable somewhere
ngin_PpuBuffer_kBufferSize = 128

; This bit has to be set in a terminating byte of a PPU buffer.
ngin_PpuBuffer_kTerminatorMask = %1000_0000

; This bit has to be set in hibyte of ppuAddress of ngin_PpuBufferElement for
; PPU address to be increased by 32 for each data byte. Otherwise increase is 1.
ngin_PpuBuffer_kIncrease32Mask = %0100_0000

.struct ngin_PpuBuffer_Element
    ; PPU address, big endian
    ppuAddress  .dbyt

    ; Size of "data". 0 means 256 bytes.
    size        .byte

    ; Data comprises of "size" bytes.
    data        .tag __ngin_EmptyStruct
.endstruct

; PPU buffer
.global ngin_PpuBuffer_buffer

; Index to the first usable byte within ngin_ppuBuffer.
.global ngin_PpuBuffer_pointer

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
