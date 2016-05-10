-- This file contains a module that can be used to access map data from Lua
-- code.

local MapData = {}

-- Width of the scrollable area view that should be valid at any given time.
-- Maximum possible value depends on the used mirroring mode:
--   * One screen mirroring: 256-8, 240-8; 256-16, 240-16
--     * Can also be used with other mirroring modes, but produces needless
--       artifacts.
--   * Horizontal mirroring: 256-8, 240; 256-16, 240
--   * Vertical mirroring: 256, 240-8; 256, 240-16
--   * Four-screen mirroring: 256, 240; 256, 240
-- Custom sizes (e.g. 64x64) could be used as well.
-- Note: The "maximum" is the maximum sensible value. E.g. with horizontal
--       mirroring the view height could be 384 pixels, but most of the updated
--       pixels would then go to waste. The tile and color attribute view
--       sizes can also differ.
-- Note: Using values other than "one screen mirroring" here requires manual
--       changes to attributeCache handling.
MapData.kViewWidth      = ngin_cfg_MapData_viewWidth
MapData.kViewHeight     = ngin_cfg_MapData_viewHeight
MapData.kAttrViewWidth  = ngin_cfg_MapData_attrViewWidth
MapData.kAttrViewHeight = ngin_cfg_MapData_attrViewHeight

local kTile8Width, kTile8Height = 8, 8
local kTile16Width, kTile16Height = 16, 16
local kTile32Width, kTile32Height = 32, 32
local kScreenWidth, kScreenHeight = 256, 256

-- Members of ngin_MapData_Pointers struct
-- \todo If scopes were exposed from NDX, structs could be handled
--       automatically with a proxy object which would be constructed based
--       on a struct scope name.
local pointersStructMembers = {
    screenRowPointersLo         = 0,
    screenRowPointersHi         = 1,
    screenPointersLo            = 2,
    screenPointersHi            = 3,
    _16x16MetatileTopLeft       = 4,
    _16x16MetatileTopRight      = 5,
    _16x16MetatileBottomLeft    = 6,
    _16x16MetatileBottomRight   = 7,
    _16x16MetatileAttributes0   = 8,
    _32x32Metatile0TopLeft      = 9,
    _32x32Metatile0TopRight     = 10,
    _32x32Metatile0BottomLeft   = 11,
    _32x32Metatile0BottomRight  = 12,
    _32x32Metatile1TopLeft      = 13,
    _32x32Metatile1TopRight     = 14,
    _32x32Metatile1BottomLeft   = 15,
    _32x32Metatile1BottomRight  = 16,
    objectsXLo                  = 17,
    objectsXHi                  = 18,
    objectsYLo                  = 19,
    objectsYHi                  = 20,
    objectsType                 = 21,
    objectsXToYIndex            = 22,
    objectsYSortedIndex         = 23
}

local ngin_MapData_header   = SYM.ngin_MapData_header[ 1 ]
local ngin_MapData_pointers = SYM.ngin_MapData_pointers[ 1 ]

-- Read a value of a map data pointer.
local function readPointer( structMember )
    return ngin.read16( ngin_MapData_pointers +
                        2 * pointersStructMembers[ structMember ] )
end

function MapData.widthScreens()
    local headerAddress = ngin.read16( ngin_MapData_header )
    return NDX.readMemory( headerAddress + 0 )
end

function MapData.heightScreens()
    local headerAddress = ngin.read16( ngin_MapData_header )
    return NDX.readMemory( headerAddress + 1 )
end

function MapData.numObjects()
    local headerAddress = ngin.read16( ngin_MapData_header )
    return NDX.readMemory( headerAddress + 10 )
end

-- Read a 16x16px metatile from the map. X and Y parameters are in pixels.
function MapData.readMetatile16( x, y )
    -- Assert that X and Y coordinates are within map range.
    -- Add 1 to the width and height because of the sentinel row/column.
    assert( x >= 0 and x < ( MapData.widthScreens()  + 1 )  * kScreenWidth,
        string.format( "readMetatile16: x coordinate out of range: %d", x ) )
    assert( y >= 0 and y < ( MapData.heightScreens() + 1 ) * kScreenHeight,
        string.format( "readMetatile16: y coordinate out of range: %d", y ) )

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

    -- Read the 32x32px metatile (lobyte).
    local index = tile32Y * 8 + tile32X
    local metatile32 = NDX.readMemory( screenPointer + index )
    -- The MSB (of 9-bit metatile index) is bitpacked at the end of the
    -- screen array so that each byte represents a row.
    local msb = bit32.band( bit32.rshift(
        NDX.readMemory( screenPointer + 8*8 + tile32Y ), 7 - tile32X ), 1 )

    -- Read the 16x16px metatile index from the 32x32px metatile.
    -- MSB selects the metatile set.
    local _32x32MetatileTopLeft, _32x32MetatileTopRight,
          _32x32MetatileBottomLeft, _32x32MetatileBottomRight
    if msb == 0 then
        _32x32MetatileTopLeft     = readPointer( "_32x32Metatile0TopLeft" )
        _32x32MetatileTopRight    = readPointer( "_32x32Metatile0TopRight" )
        _32x32MetatileBottomLeft  = readPointer( "_32x32Metatile0BottomLeft" )
        _32x32MetatileBottomRight = readPointer( "_32x32Metatile0BottomRight" )
    else
        _32x32MetatileTopLeft     = readPointer( "_32x32Metatile1TopLeft" )
        _32x32MetatileTopRight    = readPointer( "_32x32Metatile1TopRight" )
        _32x32MetatileBottomLeft  = readPointer( "_32x32Metatile1BottomLeft" )
        _32x32MetatileBottomRight = readPointer( "_32x32Metatile1BottomRight" )
    end

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

-- Read an object based on an X sorted index.
function MapData.readObjectXSorted( index )
    assert( index >= 0 and index < MapData.numObjects(), string.format(
            "readObjectXSorted: index out of range: %d", index ) )

    local objectsXLo  = readPointer( "objectsXLo" )
    local objectsXHi  = readPointer( "objectsXHi" )
    local objectsYLo  = readPointer( "objectsYLo" )
    local objectsYHi  = readPointer( "objectsYHi" )
    local objectsType = readPointer( "objectsType" )

    local xLo  = NDX.readMemory( objectsXLo  + index )
    local xHi  = NDX.readMemory( objectsXHi  + index )
    local yLo  = NDX.readMemory( objectsYLo  + index )
    local yHi  = NDX.readMemory( objectsYHi  + index )
    local type = NDX.readMemory( objectsType + index )

    local x = bit32.bor( bit32.lshift( xHi, 8 ), xLo )
    local y = bit32.bor( bit32.lshift( yHi, 8 ), yLo )

    return {
        x       = x,
        y       = y,
        type    = type
    }
end

-- Converts index in the Y sorted list to an index in the X sorted list.
function MapData.objectYToXIndex( index )
    -- Get the index to the X list from another list.
    local objectsYSortedIndex = readPointer( "objectsYSortedIndex" )
    return NDX.readMemory( objectsYSortedIndex + index )
end

-- Converts index in the X sorted list to an index in the Y sorted list.
function MapData.objectXToYIndex( index )
    -- Get the index to the Y list from another list.
    local objectsXToYIndex = readPointer( "objectsXToYIndex" )
    return NDX.readMemory( objectsXToYIndex + index )
end

-- Read an object based on an Y sorted index.
function MapData.readObjectYSorted( index )
    assert( index >= 0 and index < MapData.numObjects(), string.format(
            "readObjectYSorted: index out of range: %d", index ) )

    return MapData.readObjectXSorted( MapData.objectYToXIndex( index ) )
end

function MapData.adjustX()
    return -0x8000 + kScreenWidth * math.floor( MapData.widthScreens() / 2 )
end

function MapData.adjustY()
    return -0x8000 + kScreenHeight * math.floor( MapData.heightScreens() / 2 )
end

return MapData
