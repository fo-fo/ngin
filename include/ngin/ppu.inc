.if .not .defined( NGIN_PPU_INC_INCLUDED )
NGIN_PPU_INC_INCLUDED = 1

.include "ngin/core.inc"

.scope ppu
    .enum
        ctrl    = $2000
        mask
        status
        scroll  = $2005
        addr
        data
    .endenum

    .scope oam
        .enum
            addr    = $2003
            data
            ; OAM DMA register is technically part of the 2A0x, but logically
            ; part of the PPU.
            dma     = $4014
        .endenum

        .struct Object
            y_          .byte
            tile        .byte
            attributes  .byte
            x_          .byte
        .endstruct
    .endscope

    .scope ctrl
        ; \todo Bitmasks
    .endscope

    .scope mask
        kGrayscale          =         %1
        kShowBackgroundLeft =        %10
        kShowSpritesLeft    =       %100
        kShowBackground     =      %1000
        kShowSprites        =    %1_0000
        ; \note Red and green emphasis bits have the opposite meaning on NTSC
        ;       vs PAL.
        kNtscEmphasizeRed   =   %10_0000
        kPalEmphasizeGreen  =   %10_0000
        kNtscEmphasizeGreen =  %100_0000
        kPalEmphasizeRed    =  %100_0000
        kEmphasizeBlue      = %1000_0000
    .endscope

    ; Addresses in PPU memory space
    backgroundPalette = $3F00
    spritePalette     = backgroundPalette+$10
.endscope

.global __ngin_pollVBlank
.macro ngin_pollVBlank
    jsr __ngin_pollVBlank
.endmacro

.macro ngin_setPpuAddress address
    ; \note Big endian write order
    .if .match( .left( 1, {address} ), # )
        .local addressStripped
        addressStripped = .right( .tcount( {address} ) - 1, {address} )
        ngin_mov8 ppu::addr, #.hibyte( addressStripped )
        ngin_mov8 ppu::addr, #.lobyte( addressStripped )
    .else
        ngin_mov8 ppu::addr, 1+(address)
        ngin_mov8 ppu::addr, 0+(address)
    .endif
.endmacro

.endif
