local MapData = require( "map-data" )

local MapCollision = {}

-- Width and height of a "screen" in the map format
local kScreenSize = 256
-- Width and height of a 16x16px metatile in the map format
-- (only used to show semantic meaning in code)
local kTile16Size = 16

-- Reads a 16-bit value from RAM (based on a symbol)
local function read16Symbol( symbol )
    local addr = SYM[ symbol ][ 1 ]

    return bit32.bor(
        bit32.lshift( RAM[ addr+1 ], 8 ),
        RAM[ addr+0 ]
    )
end

-- Writes a 16-bit value to RAM (based on a symbol)
local function write16Symbol( symbol, value )
    local addr = SYM[ symbol ][ 1 ]

    RAM[ addr+1 ] = bit32.band( bit32.rshift( value, 8 ), 0xFF )
    RAM[ addr+0 ] = bit32.band( value, 0xFF )
end

-- Generic (horizontal/vertical) line segment collision routine
-- Comments and variable naming are for the horizontal case, but also works
-- for the vertical case by swapping axes.
local function lineSegmentCollisionGeneric(
    x, y0, length, deltaX, flags,
    adjustX, adjustY,
    readAttribute,
    direction,
    eject
)
    -- If deltaX is zero, no movement and thus no collision occurs.
    if eject and deltaX == 0 then
        return false, x
    end

    -- \todo Assert that deltaX isn't too small/big to avoid tunneling.

    -- Adjust the incoming coordinates so that we can index the map
    -- properly. The adjustment is done for the hibyte only (precise up to
    -- screen level).
    local mapX  = x  + adjustX
    local mapY0 = y0 + adjustY

    -- \todo Could do a sanity check here to verify that the current line
    --       segment is not inside a solid.

    local newMapX = mapX + deltaX

    -- Assume there's no ejection by default.
    local ejectedX = newMapX
    local hitSolid = false
    -- Bitwise OR of all tile attributes encountered during scanning.
    local scannedAttributes = 0

    -- \note Has to match ngin_MapData_Attributes0::kSolid from map-data.inc.
    --       No way to do automatic verification of that currently,
    --       unfortunately, because scopes can't be accessed from Lua.
    local kSolid    = 0x4
    local kSolidTop = 0x8
    local kScanAll  = 0x80 -- ngin_MapCollision_Flags::kScanAll

    local scanAll = bit32.btest( flags, kScanAll )

    local mapTileY0 = math.floor( mapY0 / kTile16Size )
    local mapTileY1 = math.floor( ( mapY0 + length - 1 ) / kTile16Size )
    for tileY = mapTileY0, mapTileY1 do
        local pixelY = tileY * kTile16Size
        local attribute = readAttribute( newMapX, pixelY )
        scannedAttributes = bit32.bor( scannedAttributes, attribute )

        -- Special handling for solids, but only in ejecting routines AND
        -- only if we haven't hit a solid yet (optimization).
        if eject and not hitSolid then
            if bit32.btest( attribute, kSolid ) then
                hitSolid = true
                -- Calculate ejected X. Correct result depends on movement
                -- direction.
                if deltaX > 0 then
                    ejectedX = math.floor( newMapX / kTile16Size ) * kTile16Size - 1
                else
                    ejectedX = math.floor( newMapX / kTile16Size ) * kTile16Size +
                                                                     kTile16Size
                end
                -- No need to check further.
                if not scanAll then break end
            elseif bit32.btest( attribute, kSolidTop ) then
                -- "Solid top" is a one-way platform that blocks movement only from
                -- the top side.
                -- Only check for the vertical case and only when moving down.
                -- \note X is Y, Y is X.
                if direction == "vertical" and deltaX > 0 then
                    -- Collide only if the line segment was previously above the
                    -- tile (to allow movement down within the tile).
                    local newTileX = math.floor( newMapX / kTile16Size )
                    local oldTileX = math.floor(    mapX / kTile16Size )
                    if oldTileX < newTileX then
                        hitSolid = true
                        ejectedX = newTileX * kTile16Size - 1
                        if not scanAll then break end
                    end
                end
            end
        end
    end

    return hitSolid, ejectedX - adjustX, scannedAttributes
end

function MapCollision.lineSegmentEjectHorizontal()
    local x  = read16Symbol( "__ngin_MapCollision_lineSegmentEjectHorizontal_x" )
    local y0 = read16Symbol( "__ngin_MapCollision_lineSegmentEjectHorizontal_y0" )
    local length = RAM.__ngin_MapCollision_lineSegmentEjectHorizontal_length
    local deltaX = ngin.signed8(
        RAM.__ngin_MapCollision_lineSegmentEjectHorizontal_deltaX
    )
    local flags = RAM.__ngin_MapCollision_lineSegmentEjectHorizontal_flags

    local hitSolid, ejectedX, scannedAttributes = lineSegmentCollisionGeneric(
        x, y0, length, deltaX, flags,
        MapData.adjustX(), MapData.adjustY(),
        MapData.readAttribute,
        "horizontal",
        true
    )

    if hitSolid then REG.C = 1 else REG.C = 0 end
    write16Symbol( "ngin_MapCollision_lineSegmentEjectHorizontal_ejectedX",
                   ejectedX )
    RAM.ngin_MapCollision_lineSegmentEjectHorizontal_scannedAttributes =
        scannedAttributes
end

function MapCollision.lineSegmentEjectVertical()
    local y  = read16Symbol( "__ngin_MapCollision_lineSegmentEjectVertical_y" )
    local x0 = read16Symbol( "__ngin_MapCollision_lineSegmentEjectVertical_x0" )
    local length = RAM.__ngin_MapCollision_lineSegmentEjectVertical_length
    local deltaY = ngin.signed8(
        RAM.__ngin_MapCollision_lineSegmentEjectVertical_deltaY
    )
    local flags = RAM.__ngin_MapCollision_lineSegmentEjectVertical_flags

    local hitSolid, ejectedY, scannedAttributes = lineSegmentCollisionGeneric(
        y, x0, length, deltaY, flags,
        MapData.adjustY(), MapData.adjustX(),
        function ( x, y ) return MapData.readAttribute( y, x ) end,
        "vertical",
        true
    )

    if hitSolid then REG.C = 1 else REG.C = 0 end
    write16Symbol( "ngin_MapCollision_lineSegmentEjectVertical_ejectedY",
                   ejectedY )
    RAM.ngin_MapCollision_lineSegmentEjectVertical_scannedAttributes =
        scannedAttributes
end

function MapCollision.lineSegmentOverlapHorizontal()
    local x  = read16Symbol( "__ngin_MapCollision_lineSegmentOverlapHorizontal_x" )
    local y0 = read16Symbol( "__ngin_MapCollision_lineSegmentOverlapHorizontal_y0" )
    local length = RAM.__ngin_MapCollision_lineSegmentOverlapHorizontal_length

    local _, _, scannedAttributes = lineSegmentCollisionGeneric(
        x, y0, length, 0, 0,
        MapData.adjustX(), MapData.adjustY(),
        MapData.readAttribute,
        "horizontal",
        false
    )

    RAM.ngin_MapCollision_lineSegmentOverlapHorizontal_scannedAttributes =
        scannedAttributes
end

function MapCollision.lineSegmentOverlapVertical()
    local y  = read16Symbol( "__ngin_MapCollision_lineSegmentOverlapVertical_y" )
    local x0 = read16Symbol( "__ngin_MapCollision_lineSegmentOverlapVertical_x0" )
    local length = RAM.__ngin_MapCollision_lineSegmentOverlapVertical_length

    local _, _, scannedAttributes = lineSegmentCollisionGeneric(
        y, x0, length, 0, 0,
        MapData.adjustY(), MapData.adjustX(),
        function ( x, y ) return MapData.readAttribute( y, x ) end,
        "vertical",
        false
    )

    RAM.ngin_MapCollision_lineSegmentOverlapVertical_scannedAttributes =
        scannedAttributes
end

ngin.MapCollision = MapCollision
