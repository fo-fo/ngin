-- This file contains a prototype Lua model of the ngin map scroller module.
-- The implementation details don't represent the final 6502 implementation,
-- but the functionality should be the same.

MapData = require( "map-data" )

local MapScroller = {}

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
local kViewWidth, kViewHeight = 256-8, 240-8 -- One screen mirroring (generic)
local kAttrViewWidth, kAttrViewHeight = 256-16, 240-16 -- One screen mirroring (generic)

local kDirectionVertical, kDirectionHorizontal = 0, 1
local kEdgeLeft, kEdgeRight, kEdgeTop, kEdgeBottom = 0, 1, 2, 3

local kTile8Width, kTile8Height = 8, 8
local kTile16Width, kTile16Height = 16, 16
local kTile32Width, kTile32Height = 32, 32
local kScreenWidth, kScreenHeight = 256, 256

local kNametableWidth = 256
local kNametableHeight = 240
local kNametableTotalWidth = 2*kNametableWidth
local kNametableTotalHeight = 2*kNametableHeight

-- These values are (in pixels) the maximum amount of pixels that need to be
-- updated when the screen scrolls. The reason for adding another 8 pixels is
-- that when the subtile offset is non-zero, one more tile of map is overlapped
-- by the view window. These values are the worst case scenario -- if subtile
-- offset is 0, only kViewWidth/kViewHeight pixels would need to be updated.
local kTileUpdateWidthPixels = kViewWidth + kTile8Width
local kTileUpdateHeightPixels = kViewHeight + kTile8Height
local kAttributeTileUpdateWidthPixels = kAttrViewWidth + kTile16Width
local kAttributeTileUpdateHeightPixels = kAttrViewHeight + kTile16Height

-------------------------------------------------------------------------------

-- Position of the edge of scroll (the first/last visible pixel row/column)
-- in both the map and the nametables, for all scroll directions.
-- \note In practice, map position and PPU position could share the same
--       subtile offset, and should be split into several parts for faster
--       access (e.g. screen part, tile part, subtile offset, ...)
--       There's also some redundancy in the tile/attribute counters.
-- \note Map position and PPU position have to be aligned to the color attribute
--       grid.
-- \note The values of these variables are set in the setPosition() function.
local scrollDataTop
local scrollDataBottom
local scrollDataLeft
local scrollDataRight

-------------------------------------------------------------------------------

-- Retrieve values of some of the symbols defined by ngin.
local ngin_PpuBuffer_buffer        = SYM.ngin_PpuBuffer_buffer[ 1 ]

-- Attribute cache keeps a copy of the PPU color attributes in CPU memory.
-- The required size depends on the view size. 9x9 bytes should be enough for
-- all uses (although addressing the cache might be a bit tricky).
local attributeCache = {}
-- for i = 0, 255 do -- 4-screen
for i = 0, 63 do
    attributeCache[ i ] = 0
end

-- Add a byte to PPU buffer.
local function addPpuBufferByte( value )
    RAM[ ngin_PpuBuffer_buffer + RAM.ngin_PpuBuffer_pointer ] = value
    RAM.ngin_PpuBuffer_pointer = RAM.ngin_PpuBuffer_pointer + 1
end

-- Terminate the PPU buffer.
local function terminatePpuBuffer()
    RAM[ ngin_PpuBuffer_buffer + RAM.ngin_PpuBuffer_pointer ] = 0x80
end

-- Stores the position of the "size" byte within the buffer, so that we know
-- where to update it later.
local ppuBufferSizePointer = nil

-- Start counting the size of a PPU buffer update.
local function startPpuBufferSizeCounting()
    ppuBufferSizePointer = RAM.ngin_PpuBuffer_pointer
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
    local size = RAM.ngin_PpuBuffer_pointer - ppuBufferSizePointer - 1

    -- Update the size in the buffer.
    RAM[ ngin_PpuBuffer_buffer + ppuBufferSizePointer ] = size

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

-- Generate a PPU attribute table address from coordinates (0..511, 0..479)
local function ppuAttributeAddressFromCoord( x, y )
    local nametable = 2 * ( math.floor( y / kNametableHeight ) % 2 ) +
                      math.floor( x / kNametableWidth ) % 2

    local attributeByteX = math.floor( x / kTile32Width ) %
                    ( kNametableWidth / kTile32Width )
    -- \note The nametable height (240px) is not an even multiple of attribute
    --       byte height (32px).
    local attributeByteY = math.floor( ( y % kNametableHeight ) / kTile32Height )

    return 0x2000 + 0x400 * nametable + 32*30 + 8*attributeByteY + attributeByteX
end

-- Updates attribute cache with attributeBits at (x, y), returns the updated
-- attribute byte corresponding to the coordinates.
local function updateAttributeCache( x, y, attributeBits )
    local attributeAddress = ppuAttributeAddressFromCoord( x, y )

    -- Strip out the nametable portion, leave only the attribute part.
    -- \todo Mask 0x3F works for a limited view size (one screen mirroring)
    --       For bigger views we would need a slightly bigger cache.
    attributeAddress = bit32.bor(
        bit32.band( attributeAddress, 0x3F ),
        -- Add the attribute bits to expand to 8-bit range.
        -- bit32.rshift( bit32.band( attributeAddress, 0xC00 ), 4 ) -- 4-screen
        0
    )

    -- Get the quadrant within the attribute byte.
    local attributeQuadrantX = math.floor( x / kTile16Width ) % 2
    -- \note A possibility of a subtle error here requires us to modulo the
    --       Y coordinate with nametable height before division. Otherwise
    --       e.g. Y = 240 would produce quadrantY = 1
    local attributeQuadrantY = math.floor( ( y % kNametableHeight ) / kTile16Height ) % 2

    -- Calculate the shift amount.
    -- (0,0) -> 0, (0,1) -> 2, (1,0) -> 4, (1,1) -> 6
    local shiftAmount = 2 * ( 2*attributeQuadrantY + attributeQuadrantX )

    -- Update the cache.
    local attributeByte = attributeCache[ attributeAddress ]
    attributeByte = bit32.bor(
        -- Clear out the existing data with AND.
        bit32.band( attributeByte, bit32.bnot( bit32.lshift( 0x3, shiftAmount ) ) ),
        bit32.lshift( attributeBits, shiftAmount )
    )
    attributeCache[ attributeAddress ] = attributeByte

    return attributeByte

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

    -- \note Even though the update length is a constant, this will never read
    --       from outside the map data boundaries even at the edges, because
    --       sentinel screens are added to the map edges when importing.

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
            tile = MapData.readTile( mapX, mapY )
        else
            tile = MapData.readTile( mapY, mapX )
        end
        addPpuBufferByte( tile )
    end

    endPpuBufferSizeCounting()
    terminatePpuBuffer()
end

-- Mostly copied from update(). Annoyingly different enough to make combining
-- the two functions quite difficult.
local function updateAttributes( scrollData, perpScrollData )
    local kUpdateLengthPixels, kAttributeTileSize
    if scrollData.updateDirection == kDirectionVertical then
        kUpdateLengthPixels = kAttributeTileUpdateHeightPixels
        kAttributeTileSize = kTile16Height
    else
        kUpdateLengthPixels = kAttributeTileUpdateWidthPixels
        kAttributeTileSize = kTile16Width
    end

    local previousPpuAddress = nil

    local mapX = scrollData.attrMapPosition
    for mapY = perpScrollData.attrMapPosition,
            perpScrollData.attrMapPosition+kUpdateLengthPixels-1,
            kAttributeTileSize do

        ppuY = perpScrollData.attrPpuPosition + mapY - perpScrollData.attrMapPosition

        local ppuAddress
        if scrollData.updateDirection == kDirectionVertical then
            ppuAddress = ppuAttributeAddressFromCoord( scrollData.attrPpuPosition,
                                                       ppuY )
        else
            ppuAddress = ppuAttributeAddressFromCoord( ppuY,
                                                       scrollData.attrPpuPosition )
        end

        -- If update is to the same address as before, replace the old update.
        -- This can happen because several attributes are packed into a single
        -- byte.
        if ppuAddress == previousPpuAddress then
            -- Replace the previous update by moving the pointer backwards.
            RAM.ngin_PpuBuffer_pointer = RAM.ngin_PpuBuffer_pointer - 1
        -- If nametable changed, OR doing a vertical update, start a new update
        -- batch (always needed for vertical, since there's no "inc8" mode)
        elseif previousPpuAddress == nil or bit32.band( ppuAddress, 0xC00 ) ~=
                bit32.band( previousPpuAddress, 0xC00 ) or
                scrollData.updateDirection == kDirectionVertical then
            endPpuBufferSizeCounting()

            -- \note Inc1 mode is always used for attributes.

            addPpuBufferByte( bit32.rshift( ppuAddress, 8 ) )
            addPpuBufferByte( bit32.band( ppuAddress, 0xFF ) )
            startPpuBufferSizeCounting()
            addPpuBufferByte( 0 )
        end
        previousPpuAddress = ppuAddress

        -- Read an attribute from the map, combine it with cached attributes,
        -- store back in cache, and add to the update buffer.
        local attribute
        if scrollData.updateDirection == kDirectionVertical then
            local colorAttributeBits = bit32.band(
                MapData.readAttribute( mapX, mapY ), 0x3 )
            attribute = updateAttributeCache( scrollData.attrPpuPosition, ppuY,
                colorAttributeBits )
        else
            local colorAttributeBits = bit32.band(
                MapData.readAttribute( mapY, mapX ), 0x3 )
            attribute = updateAttributeCache( ppuY, scrollData.attrPpuPosition,
                colorAttributeBits )
        end

        addPpuBufferByte( attribute )
    end

    endPpuBufferSizeCounting()
    terminatePpuBuffer()
end

local function scroll( amount, scrollData, oppositeScrollData, perpScrollData )
    local previousPosition = scrollData.mapPosition
    local previousAttrPosition = scrollData.attrMapPosition

    -- Check amount against the map size. On left/top side can never go below 0.
    -- On right/bottom side can never go above map width/height.
    -- Attribute window is used for reference because it's smaller than the
    -- tile window (or equal in size).
    -- \todo Could optionally operate in repeating mode by rolling the
    --       coordinates over (although that would't automatically translate
    --       to e.g. collision routines working in the same way).
    if scrollData.edge == kEdgeLeft or scrollData.edge == kEdgeTop then
        -- Clamp the amount so that we won't go over the edge.
        -- Note that amount is negative when moving left/up.
        if scrollData.attrMapPosition + amount < 0 then
            amount = -scrollData.attrMapPosition
        end
    elseif scrollData.edge == kEdgeRight or scrollData.edge == kEdgeBottom then
        local mapSizePixels
        -- \note updateDirection is the direction of PPU updates, so it's
        --       opposite of the movement direction.
        if scrollData.updateDirection == kDirectionVertical then
            mapSizePixels = MapData.widthScreens() * kScreenWidth
        elseif scrollData.updateDirection == kDirectionHorizontal then
            mapSizePixels = MapData.heightScreens() * kScreenHeight
        end
        local maxScroll = mapSizePixels - 1
        if scrollData.attrMapPosition + amount > maxScroll then
            amount = maxScroll - scrollData.attrMapPosition
        end
    end

    -- Update the position in the map, on the side we're scrolling to, and on
    -- the opposite side.
    scrollData.mapPosition = scrollData.mapPosition + amount
    oppositeScrollData.mapPosition = oppositeScrollData.mapPosition + amount

    scrollData.attrMapPosition = scrollData.attrMapPosition + amount
    oppositeScrollData.attrMapPosition = oppositeScrollData.attrMapPosition + amount

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

    scrollData.attrPpuPosition =
        (scrollData.attrPpuPosition + amount) % kPpuPositionMax
    oppositeScrollData.attrPpuPosition =
        (oppositeScrollData.attrPpuPosition + amount) % kPpuPositionMax

    -- If the scroll position update pushed us over to a new tile, we need to
    -- update a new tile row/column. In an actual implementation we could check
    -- if the subtile offset overflowed.
    if math.floor( previousPosition/8 ) ~=
            math.floor( scrollData.mapPosition/8 ) then
        -- A new tile row/column is visible, generate PPU update for it.
        update( scrollData, perpScrollData )
    end

    if math.floor( previousAttrPosition/16 ) ~=
            math.floor( scrollData.attrMapPosition/16 ) then
        updateAttributes( scrollData, perpScrollData )
    end

    -- Return how much was actually scrolled.
    return amount
end

local function setPosition( x, y )
    -- These values need to be added to position to go from world coordinates
    -- to map coordinates.
    local adjustX = MapData.adjustX()
    local adjustY = MapData.adjustY()

    x = x + adjustX
    y = y + adjustY

    scrollDataTop = {
        mapPosition = y,
        -- \note Any PPU position should be fine as long as the color grids of
        --       map and PPU coordinates are properly aligned.
        ppuPosition = y % kTile16Height,
        attrMapPosition = y,
        attrPpuPosition = y % kTile16Height,
        updateDirection = kDirectionHorizontal,
        edge = kEdgeTop
    }

    -- Bottom coordinates are completely based on the top coordinates.
    scrollDataBottom = {
        mapPosition = scrollDataTop.mapPosition + kViewHeight-1,
        ppuPosition = (scrollDataTop.ppuPosition + kViewHeight-1) % kNametableTotalHeight,
        attrMapPosition = scrollDataTop.attrMapPosition + kAttrViewHeight-1,
        attrPpuPosition = (scrollDataTop.attrPpuPosition + kAttrViewHeight-1) % kNametableTotalHeight,
        updateDirection = kDirectionHorizontal,
        edge = kEdgeBottom
    }

    -- Left and right side are handled similarly as top/bottom.

    scrollDataLeft = {
        mapPosition = x,
        ppuPosition = x % kTile16Width,
        attrMapPosition = x,
        attrPpuPosition = x % kTile16Width,
        updateDirection = kDirectionVertical,
        edge = kEdgeLeft
    }

    scrollDataRight = {
        mapPosition = scrollDataLeft.mapPosition + kViewWidth-1,
        ppuPosition = (scrollDataLeft.ppuPosition + kViewWidth-1) % kNametableTotalWidth,
        attrMapPosition = scrollDataLeft.attrMapPosition + kAttrViewWidth-1,
        attrPpuPosition = (scrollDataLeft.attrPpuPosition + kAttrViewWidth-1) % kNametableTotalWidth,
        updateDirection = kDirectionVertical,
        edge = kEdgeRight
    }
end

function MapScroller.setPosition()
    local positionAddr = SYM.__ngin_MapScroller_setPosition_position[ 1 ]
    local x = ngin.read16( positionAddr + 0 )
    local y = ngin.read16( positionAddr + 2 )
    setPosition( x, y )
end

function MapScroller.scrollHorizontal()
    local amount = ngin.signedByte( RAM.__ngin_MapScroller_scrollHorizontal_amount )

    local actualAmount
    if amount < 0 then
        actualAmount = scroll( amount, scrollDataLeft, scrollDataRight, scrollDataTop )
    elseif amount > 0 then
        actualAmount = scroll( amount, scrollDataRight, scrollDataLeft, scrollDataTop )
    end

    REG.A = actualAmount
end

function MapScroller.scrollVertical()
    local amount = ngin.signedByte( RAM.__ngin_MapScroller_scrollVertical_amount )

    local actualAmount
    if amount < 0 then
        actualAmount = scroll( amount, scrollDataTop, scrollDataBottom, scrollDataLeft )
    elseif amount > 0 then
        actualAmount = scroll( amount, scrollDataBottom, scrollDataTop, scrollDataLeft )
    end

    REG.A = actualAmount
end

function MapScroller.ppuRegisters()
    local horizontalNametable = math.floor( scrollDataLeft.ppuPosition /
                                            kNametableWidth )
    local verticalNametable   = math.floor( scrollDataTop.ppuPosition /
                                            kNametableHeight )

    assert( horizontalNametable == 0 or horizontalNametable == 1 )
    assert( verticalNametable   == 0 or verticalNametable   == 1 )

    local scrollX = scrollDataLeft.ppuPosition % kNametableWidth
    local scrollY = scrollDataTop .ppuPosition % kNametableHeight

    -- Return the results in A/X/Y.
    REG.A = 2 * verticalNametable + horizontalNametable
    REG.X = scrollX
    REG.Y = scrollY
end

ngin.MapScroller = MapScroller
