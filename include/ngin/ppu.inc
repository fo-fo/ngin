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
        kBaseNametable0                 =        %00
        kBaseNametable1                 =        %01
        kBaseNametable2                 =        %10
        kBaseNametable3                 =        %11
        kAddressIncrement1              =       %000
        kAddressIncrement32             =       %100
        kSpritePatternTableLeft         =      %0000
        kSpritePatternTableRight        =      %1000
        kBackgroundPatternTableLeft     =    %0_0000
        kBackgroundPatternTableRight    =    %1_0000
        kSpriteSize8x8                  =   %00_0000
        kSpriteSize8x16                 =   %10_0000
        ; PPU master/slave select not exposed.
        kGenerateVblankNmi              = %1000_0000
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

    ; \todo Define bitmasks of OAM attributes(?)

    ; -------------------------------------------------------------------------
    ; Addresses in PPU memory space:
    patternTable0       = 0
    patternTable1       = $1000

    nametable0          = $2000
    attributeTable0     = nametable0 + $3C0

    nametable1          = $2400
    attributeTable1     = nametable1 + $3C0

    nametable2          = $2800
    attributeTable2     = nametable2 + $3C0

    nametable3          = $2C00
    attributeTable3     = nametable3 + $3C0

    backgroundPalette   = $3F00
    spritePalette       = backgroundPalette + $10

    ; -------------------------------------------------------------------------

    kBytesPer8x8Tile  = 16
    kBytesPer8x16Tile = 2*kBytesPer8x8Tile
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
