-- This file contains a prototype Lua model of the ngin map scroller module.
-- The implementation details don't represent the final 6502 implementation,
-- but the functionality should be the same.

-- \todo Color attribute updates

local MapScroller = {}

-- Width of the scrollable area view that should be valid at any given time.
-- 240x224 should make a good default, since it can work with any mirroring
-- mode, although it will show artifacts on both axes.
-- "Minus 16" comes from the size of the color attribute block.
local kViewWidth, kViewHeight = 256-16, 240-16 -- One screen mirroring (generic)
-- local kViewWidth, kViewHeight = 256-16, 240 -- Horizontal mirroring
-- local kViewWidth, kViewHeight = 256, 240-16 -- Vertical mirroring
-- local kViewWidth, kViewHeight = 256, 240 -- Four-screen mirroring
-- local kViewWidth, kViewHeight = 64, 64 -- Custom

local kDirectionVertical, kDirectionHorizontal = 0, 1

local kTile8Width, kTile8Height = 8, 8
local kTile16Width, kTile16Height = 16, 16
local kTile32Width, kTile32Height = 32, 32
local kScreenWidth, kScreenHeight = 256, 256

local kNametableWidth = 256
local kNametableHeight = 240
local kNametableTotalWidth = 2*kNametableWidth
local kNametableTotalHeight = 2*kNametableHeight

-- These values are (in pixels) the maximum amount of pixels that need to be
-- updated when the screen scroll. The reason for adding another 8 pixels is
-- that when the subtile offset is non-zero, one more tile of map is overlapped
-- by the view window. These values are the worst case scenario -- if subtile
-- offset is 0, only kViewWidth/kViewHeight pixels would need to be updated.
local kTileUpdateWidthPixels = kViewWidth + kTile8Width
local kTileUpdateHeightPixels = kViewHeight + kTile8Height

-------------------------------------------------------------------------------

-- Position of the edge of scroll (the first/last visible pixel row/column)
-- in both the map and the nametables, for all scroll directions.
-- \note In practice, map position and PPU position could share the same
--       subtile offset, and should be split into several parts for faster
--       access (e.g. screen part, tile part, subtile offset, ...)
-- \note Map position and PPU position have to be aligned to the color attribute
--       grid.
scrollDataTop = {
    mapPosition = 0,
    ppuPosition = 0,
    updateDirection = kDirectionHorizontal
}

scrollDataBottom = {
    mapPosition = scrollDataTop.mapPosition + kViewHeight-1,
    ppuPosition = (scrollDataTop.ppuPosition + kViewHeight-1) % kNametableTotalHeight,
    updateDirection = kDirectionHorizontal
}

scrollDataLeft = {
    mapPosition = 0,
    ppuPosition = 0,
    updateDirection = kDirectionVertical
}

scrollDataRight = {
    mapPosition = scrollDataLeft.mapPosition + kViewWidth-1,
    ppuPosition = (scrollDataLeft.ppuPosition + kViewWidth-1) % kNametableTotalWidth,
    updateDirection = kDirectionVertical
}

-------------------------------------------------------------------------------

-- Reads a 16-bit value from RAM.
local function read16( addr )
    return bit32.bor(
        bit32.lshift( RAM[ addr+1 ], 8 ),
        RAM[ addr+0 ]
    )
end

-- Members of ngin_MapData_Pointers struct
-- \todo If scopes were exposed from NDX, structs could be handled
--       automatically with a proxy object which would be constructed based
--       on a struct scope name.
local pointersStructMembers = {
    screenRowPointersLo=0,
    screenRowPointersHi=1,
    screenPointersLo=2,
    screenPointersHi=3,
    _16x16MetatileTopLeft=4,
    _16x16MetatileTopRight=5,
    _16x16MetatileBottomLeft=6,
    _16x16MetatileBottomRight=7,
    _16x16MetatileAttributes0=8,
    _32x32MetatileTopLeft=9,
    _32x32MetatileTopRight=10,
    _32x32MetatileBottomLeft=11,
    _32x32MetatileBottomRight=12
}

-- Retrieve values of some of the symbols defined by ngin.
local ngin_MapData_pointers = SYM.ngin_MapData_pointers[ 1 ]
local ngin_ppuBuffer        = SYM.ngin_ppuBuffer[ 1 ]

-- Read a value of a map data pointer.
local function readPointer( structMember )
    return read16( ngin_MapData_pointers +
                   2 * pointersStructMembers[ structMember ] )
end

-- Convert an unsigned byte to a signed number.
local function signedByte( value )
    if value <= 127 then
        return value
    end
    return value - 256
end

-- Read a tile from map. X and Y parameters are in pixels.
local function readTile( x, y )
    -- Screen coordinates within the full map
    local screenX, screenY =
        math.floor( x / kScreenWidth ), math.floor( y / kScreenHeight )

    -- 32x32px metatile coordinates within the screen
    local tile32X, tile32Y =
        math.floor( x / kTile32Width ) % ( kScreenWidth / kTile32Width ),
        math.floor( y / kTile32Height ) % ( kScreenHeight / kTile32Height )

    -- 2x2 coordinates within the 32x32px metatile
    local tile32X_2, tile32Y_2 =
        math.floor( x / kTile16Width ) % ( kTile32Width / kTile16Width ),
        math.floor( y / kTile16Width ) % ( kTile32Height / kTile16Height )

    -- 2x2 coordinates within the 16x16px metatile
    local tile16X_2, tile16Y_2 =
        math.floor( x / kTile8Width ) % ( kTile16Width / kTile8Width ),
        math.floor( y / kTile8Width ) % ( kTile16Height / kTile8Width )

    -- Get address of screen row pointers.
    local screenRowPointersLo = readPointer( "screenRowPointersLo" )
    local screenRowPointersHi = readPointer( "screenRowPointersHi" )

    -- Get address of screen pointers.
    local screenPointersLo = readPointer( "screenPointersLo" )
    local screenPointersHi = readPointer( "screenPointersHi" )

    -- Get address of 32x32px metatile pointers.
    local _32x32MetatileTopLeft     = readPointer( "_32x32MetatileTopLeft" )
    local _32x32MetatileTopRight    = readPointer( "_32x32MetatileTopRight" )
    local _32x32MetatileBottomLeft  = readPointer( "_32x32MetatileBottomLeft" )
    local _32x32MetatileBottomRight = readPointer( "_32x32MetatileBottomRight" )

    -- Get address of 16x16px metatile pointers.
    local _16x16MetatileTopLeft     = readPointer( "_16x16MetatileTopLeft" )
    local _16x16MetatileTopRight    = readPointer( "_16x16MetatileTopRight" )
    local _16x16MetatileBottomLeft  = readPointer( "_16x16MetatileBottomLeft" )
    local _16x16MetatileBottomRight = readPointer( "_16x16MetatileBottomRight" )

    -- Index the screen row pointers list with the Y coordinate.
    local screenRowPointerLo = NDX.readMemory( screenRowPointersLo + screenY )
    local screenRowPointerHi = NDX.readMemory( screenRowPointersHi + screenY )
    local screenRowPointer = bit32.bor( bit32.lshift( screenRowPointerHi, 8 ),
                                        screenRowPointerLo )

    -- Index the screen row with the X coordinate to get the screen index.
    local screen = NDX.readMemory( screenRowPointer + screenX )

    -- Get the screen pointer lobyte and hibyte.
    local screenPointerLo = NDX.readMemory( screenPointersLo + screen )
    local screenPointerHi = NDX.readMemory( screenPointersHi + screen )
    local screenPointer = bit32.bor( bit32.lshift( screenPointerHi, 8 ),
                                     screenPointerLo )

    -- Read the 32x32px metatile.
    local index = tile32Y * 8 + tile32X
    local metatile32 = NDX.readMemory( screenPointer + index )

    -- Read the 16x16px metatile index from the 32x32px metatile.
    local addr = nil
    if tile32X_2 == 0 and tile32Y_2 == 0 then
        addr = _32x32MetatileTopLeft
    elseif tile32X_2 == 1 and tile32Y_2 == 0 then
        addr = _32x32MetatileTopRight
    elseif tile32X_2 == 0 and tile32Y_2 == 1 then
        addr = _32x32MetatileBottomLeft
    elseif tile32X_2 == 1 and tile32Y_2 == 1 then
        addr = _32x32MetatileBottomRight
    end
    local metatile16 = NDX.readMemory( addr + metatile32 )

    -- Read the 8x8px tile index from the 16x16px metatile.
    local addr = -1
    if tile16X_2 == 0 and tile16Y_2 == 0 then
        addr = _16x16MetatileTopLeft
    elseif tile16X_2 == 1 and tile16Y_2 == 0 then
        addr = _16x16MetatileTopRight
    elseif tile16X_2 == 0 and tile16Y_2 == 1 then
        addr = _16x16MetatileBottomLeft
    elseif tile16X_2 == 1 and tile16Y_2 == 1 then
        addr = _16x16MetatileBottomRight
    end
    local tile8 = NDX.readMemory( addr + metatile16 )

    return tile8

end

-- Add a byte to PPU buffer.
local function addPpuBufferByte( value )
    RAM[ ngin_ppuBuffer + RAM.ngin_ppuBufferPointer ] = value
    RAM.ngin_ppuBufferPointer = RAM.ngin_ppuBufferPointer + 1
end

-- Terminate the PPU buffer.
local function terminatePpuBuffer()
    RAM[ ngin_ppuBuffer + RAM.ngin_ppuBufferPointer ] = 0x80
end

-- Stores the position of the "size" byte within the buffer, so that we know
-- where to update it later.
local ppuBufferSizePointer = nil

-- Start counting the size of a PPU buffer update.
local function startPpuBufferSizeCounting()
    ppuBufferSizePointer = RAM.ngin_ppuBufferPointer
end

-- Stop counting the size of a PPU buffer update. Update the size byte in the
-- buffer with the correct size.
local function endPpuBufferSizeCounting()
    -- Don't do anything if buffer size counting wasn't started.
    if ppuBufferSizePointer == nil then
        return
    end

    -- Calculate the size based on current PPU pointer and where the size
    -- byte was.
    local size = RAM.ngin_ppuBufferPointer - ppuBufferSizePointer - 1

    -- Update the size in the buffer.
    RAM[ ngin_ppuBuffer + ppuBufferSizePointer ] = size

    ppuBufferSizePointer = nil
end

-- Generate a PPU nametable address from coordinates (0..511, 0..479)
local function ppuAddressFromCoord( x, y )
    local nametable = 2 * ( math.floor( y / kNametableHeight ) % 2 ) +
                      math.floor( x / kNametableWidth ) % 2

    local tileX = math.floor( x / kTile8Width ) %
                    ( kNametableWidth / kTile8Width )
    local tileY = math.floor( y / kTile8Height ) %
                    ( kNametableHeight / kTile8Height )

    return 0x2000 + 0x400 * nametable + 32*tileY + tileX
end

-- Generates a PPU buffer update to add a new row/column of tiles.
-- "Perp" stands for perpendicular.
local function update( scrollData, perpScrollData )
    -- Determine the update length and the step amount based on the update
    -- direction.
    local kUpdateLengthPixels, kTileSize
    if scrollData.updateDirection == kDirectionVertical then
        kUpdateLengthPixels = kTileUpdateHeightPixels
        kTileSize = kTile8Height
    else
        kUpdateLengthPixels = kTileUpdateWidthPixels
        kTileSize = kTile8Width
    end

    local previousPpuAddress = nil

    -- Loop through the whole section that needs to be updated. Currently the
    -- scroll speed is limited to 8px/frame.
    -- Subtract one because the for loop is inclusive in the upper bound.
    -- \note The loop variables (X and Y) are named from the point of view
    --       of a vertical update.
    local mapX = scrollData.mapPosition
    for mapY = perpScrollData.mapPosition,
            perpScrollData.mapPosition+kUpdateLengthPixels-1, kTileSize do

        -- Calculate the nametable Y corresponding to mapY.
        ppuY = perpScrollData.ppuPosition + mapY - perpScrollData.mapPosition

        -- Again, need to swap X and Y depending on the update direction.
        local ppuAddress
        if scrollData.updateDirection == kDirectionVertical then
            ppuAddress = ppuAddressFromCoord( scrollData.ppuPosition, ppuY )
        else
            ppuAddress = ppuAddressFromCoord( ppuY, scrollData.ppuPosition )
        end

        -- Check if the nametable changed. In an actual implementation, we
        -- would not want to be doing this check on each iteration.
        if previousPpuAddress == nil or bit32.band( ppuAddress, 0xC00 ) ~=
                                        bit32.band( previousPpuAddress, 0xC00 ) then
            endPpuBufferSizeCounting()

            local inc32
            if scrollData.updateDirection == kDirectionVertical then
                inc32 = 0x40
            else
                inc32 = 0
            end

            -- Add a PPU buffer update header.

            -- PPU address hibyte (+flags)
            addPpuBufferByte( bit32.bor( bit32.rshift( ppuAddress, 8 ), inc32 ) )
            -- PPU address lobyte
            addPpuBufferByte( bit32.band( ppuAddress, 0xFF ) )
            -- Add a placeholder size byte and start counting the size.
            startPpuBufferSizeCounting()
            addPpuBufferByte( 0 )
        end
        previousPpuAddress = ppuAddress

        -- Read a tile from the map and add to buffer.
        local tile
        if scrollData.updateDirection == kDirectionVertical then
            tile = readTile( mapX, mapY )
        else
            tile = readTile( mapY, mapX )
        end
        addPpuBufferByte( tile )
    end

    endPpuBufferSizeCounting()

    terminatePpuBuffer()
end

local function scroll( amount, scrollData, oppositeScrollData, perpScrollData )
    local previousPosition = scrollData.mapPosition

    -- Update the position in the map, on the side we're scrolling to, and on
    -- the opposite side.
    -- \todo If we know the map size, could clamp the value, or roll it over
    --       for a repeating map.
    scrollData.mapPosition = scrollData.mapPosition + amount
    oppositeScrollData.mapPosition = oppositeScrollData.mapPosition + amount

    -- Determine the maximum nametable coordinate based on update direction.
    local kPpuPositionMax
    if scrollData.updateDirection == kDirectionVertical then
        kPpuPositionMax = kNametableTotalWidth
    else
        kPpuPositionMax = kNametableTotalHeight
    end

    scrollData.ppuPosition =
        (scrollData.ppuPosition + amount) % kPpuPositionMax
    oppositeScrollData.ppuPosition =
        (oppositeScrollData.ppuPosition + amount) % kPpuPositionMax

    -- If the scroll position update pushed us over to a new tile, we need to
    -- update a new tile row/column. In an actual implementation we could check
    -- if the subtile offset overflowed.
    if math.floor( previousPosition/8 ) ~=
            math.floor( scrollData.mapPosition/8 ) then
        -- A new tile row/column is visible, generate PPU update for it.
        update( scrollData, perpScrollData )
    end
end

function MapScroller.scrollHorizontal()
    local amount = signedByte( RAM.__ngin_MapScroller_scrollHorizontal_amount )

    if amount < 0 then
        scroll( amount, scrollDataLeft, scrollDataRight, scrollDataTop )
    elseif amount > 0 then
        scroll( amount, scrollDataRight, scrollDataLeft, scrollDataTop )
    end
end

function MapScroller.scrollVertical()
    local amount = signedByte( RAM.__ngin_MapScroller_scrollVertical_amount )

    if amount < 0 then
        scroll( amount, scrollDataTop, scrollDataBottom, scrollDataLeft )
    elseif amount > 0 then
        scroll( amount, scrollDataBottom, scrollDataTop, scrollDataLeft )
    end
end

ngin.MapScroller = MapScroller
