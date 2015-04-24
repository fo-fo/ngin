-- This file contains a module that can be used to access map data from Lua
-- code.

local MapData = {}

local kTile8Width, kTile8Height = 8, 8
local kTile16Width, kTile16Height = 16, 16
local kTile32Width, kTile32Height = 32, 32
local kScreenWidth, kScreenHeight = 256, 256

-- Reads a 16-bit value from RAM.
local function read16( addr )
    return bit32.bor(
        bit32.lshift( NDX.readMemory( addr+1 ), 8 ),
        NDX.readMemory( addr+0 )
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

local ngin_MapData_header   = SYM.ngin_MapData_header[ 1 ]
local ngin_MapData_pointers = SYM.ngin_MapData_pointers[ 1 ]

-- Read a value of a map data pointer.
local function readPointer( structMember )
    return read16( ngin_MapData_pointers +
                   2 * pointersStructMembers[ structMember ] )
end

-- Read a 16x16px metatile from the map. X and Y parameters are in pixels.
function MapData.readMetatile16( x, y )
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

    return metatile16
end

-- Read a tile from the map.
function MapData.readTile( x, y )
    local metatile16 = MapData.readMetatile16( x, y )

    -- 2x2 coordinates within the 16x16px metatile
    local tile16X_2, tile16Y_2 =
        math.floor( x / kTile8Width ) % ( kTile16Width / kTile8Width ),
        math.floor( y / kTile8Width ) % ( kTile16Height / kTile8Width )

    -- Get address of 16x16px metatile pointers.
    local _16x16MetatileTopLeft     = readPointer( "_16x16MetatileTopLeft" )
    local _16x16MetatileTopRight    = readPointer( "_16x16MetatileTopRight" )
    local _16x16MetatileBottomLeft  = readPointer( "_16x16MetatileBottomLeft" )
    local _16x16MetatileBottomRight = readPointer( "_16x16MetatileBottomRight" )

    -- Read the 8x8px tile index from the 16x16px metatile.
    local addr = nil
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

-- Read an attribute from the map.
function MapData.readAttribute( x, y )
    local metatile16 = MapData.readMetatile16( x, y )

    local _16x16MetatileAttributes0 = readPointer( "_16x16MetatileAttributes0" )
    local attribute = NDX.readMemory( _16x16MetatileAttributes0 + metatile16 )

    return attribute
end

function MapData.widthScreens()
    local headerAddress = read16( ngin_MapData_header )
    return NDX.readMemory( headerAddress + 0 )
end

function MapData.heightScreens()
    local headerAddress = read16( ngin_MapData_header )
    return NDX.readMemory( headerAddress + 1 )
end

return MapData
