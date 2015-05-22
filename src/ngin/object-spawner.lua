-- This file contains a prototype Lua model of the Ngin object spawner module.

local MapData = require( "map-data" )

local ObjectSpawner = {}

-- \todo Keep track of what spawn points have been activated so far.
--       Need a function for setting/unsetting the spawn bit for a given
--       object list index.

-- Variables to keep track of the scroll edges, including:
-- 1) Pixel position in the map
-- 2) Index into the object list
local edgeLeft, edgeRight, edgeTop, edgeBottom

local kEdgeLeft, kEdgeRight, kEdgeTop, kEdgeBottom = 0, 1, 2, 3

local kViewSlackX = SYM.ngin_ObjectSpawner_kViewSlackX[ 1 ]
local kViewSlackY = SYM.ngin_ObjectSpawner_kViewSlackY[ 1 ]
local kInvalidSpawnIndex = SYM.ngin_ObjectSpawner_kInvalidSpawnIndex[ 1 ]

local Object_kInvalidId = SYM.ngin_Object_kInvalidId[ 1 ]

local function readSpawnData( objectListIndex )
    -- Bitfield of spawn states, one for each object in the map list.
    local spawned = SYM.__ngin_ObjectSpawner_spawned[ 1 ]

    -- Subtract 1 because the first value is a sentinel we don't care about.
    objectListIndex = objectListIndex - 1

    local byteIndex = math.floor( objectListIndex / 8 )
    local byteMask  = bit32.lshift( 1, objectListIndex % 8 )
    local address = spawned + byteIndex
    local spawnByte = RAM[ spawned + byteIndex ]

    return address, byteMask, spawnByte
end

local function objectSpawned( objectListIndex )
    local address, byteMask, spawnByte = readSpawnData( objectListIndex )

    return bit32.btest( spawnByte, byteMask )
end

local function setObjectSpawned( objectListIndex )
    local address, byteMask, spawnByte = readSpawnData( objectListIndex )

    RAM[ address ] = bit32.bor( spawnByte, byteMask )
end

local function setObjectNotSpawned( objectListIndex )
    local address, byteMask, spawnByte = readSpawnData( objectListIndex )

    RAM[ address ] = bit32.band( spawnByte, bit32.bnot( byteMask ) )
end

local function spawnObject( object, objectListIndex )
    print( string.format( "spawning object: type=%d, x=%d, y=%d, index=%d",
        object.type, object.x, object.y, objectListIndex ) )

    -- Check if the object has already been spawned. If so, don't spawn
    -- again.
    if objectSpawned( objectListIndex ) then
        print( "  object already spawned, skipping" )
        return
    end

    -- Set the constructor parameters.
    local constructorParameters = SYM.__ngin_Object_constructorParameters[ 1 ]
    -- \note Assumes that the position is the very first thing in the
    --       constructor parameter area, since we don't have access to the
    --       struct.
    ngin.write16( constructorParameters+0, object.x )
    ngin.write16( constructorParameters+2, object.y )

    RAM.ngin_ObjectSpawner_spawnIndex = objectListIndex

    -- \todo Pass custom parameters.

    RAM.__ngin_Object_new_typeId = object.type
    local ngin_Object_new = SYM.__ngin_Object_new[ 1 ]
    NDX.jsr( ngin_Object_new )

    -- Set the "spawned" flag only after successful object allocation.
    -- If object allocation fails, we want to retry the next time object comes
    -- into range.
    if REG.X ~= Object_kInvalidId then
        setObjectSpawned( objectListIndex )
    else
        print( "ObjectSpawner failed to spawn the object" )
    end

    -- Set index to invalid after spawn is done.
    RAM.ngin_ObjectSpawner_spawnIndex = kInvalidSpawnIndex
end

local function scroll( amount, edge, oppositeEdge, perpEdge, perpOppositeEdge )
    -- \note Amount can be negative

    -- \todo Factor out the decisions about edges/directions.

    edge.position = edge.position + amount
    oppositeEdge.position = oppositeEdge.position + amount

    local readFunction
    local element
    if edge.edgeId == kEdgeLeft or edge.edgeId == kEdgeRight then
        readFunction = MapData.readObjectXSorted
        element = "x"
        perpElement = "y"
    elseif edge.edgeId == kEdgeTop or edge.edgeId == kEdgeBottom then
        readFunction = MapData.readObjectYSorted
        element = "y"
        perpElement = "x"
    end

    -- \note "amount" is always negative here when edgeId is kEdgeLeft/kEdgeTop.
    local compareFunction
    local step
    if edge.edgeId == kEdgeLeft or edge.edgeId == kEdgeTop then
        compareFunction = function ( objectPosition, edgePosition )
                          return objectPosition >= edgePosition end
        oppositeCompareFunction = function ( objectPosition, edgePosition )
                                  return objectPosition > edgePosition end
        step = -1
    elseif edge.edgeId == kEdgeRight or edge.edgeId == kEdgeBottom then
        compareFunction = function ( objectPosition, edgePosition )
                          return objectPosition <= edgePosition end
        oppositeCompareFunction = function ( objectPosition, edgePosition )
                                  return objectPosition < edgePosition end
        step = 1
    end

    -- In the direction that is being scrolled to, check whether the object
    -- has come into view. Repeat for each object until we find an object that
    -- is not in view.
    -- \note "Coming in to view" means that the coordinate matches. The
    --       perpendicular coordinate decides whether the object is really in
    --       view.
    while true do
        local object = readFunction( edge.objectIndex )
        local enteredView = compareFunction( object[ element ], edge.position )
        if enteredView then
            -- Check if within range in the perpendicular direction. E.g. if
            -- scrolling horizontally, check the Y coordinate.
            if object[ perpElement ] >= perpEdge.position and
               object[ perpElement ] <= perpOppositeEdge.position then
                -- If edge.objectIndex is an index into the Y-sorted list,
                -- we need to grab the X-sorted list index.
                local objectIndex = edge.objectIndex
                if element == "y" then
                    objectIndex = MapData.objectYToXIndex( edge.objectIndex )
                end
                -- Spawn the object. Calls back into 6502 code.
                spawnObject( object, objectIndex )
            else
                -- \todo Not in range, but for special object types this event
                --       might be interesting (= crossing a certain horizontal
                --       or vertical boundary)
            end

            edge.objectIndex = edge.objectIndex + step
        else
            -- If object is not in view, nothing to do. Recheck on next scroll.
            break
        end
    end

    -- Check the opposite edge, and see if an object has left the view.
    -- For any objects that have left the view, adjust the list index.
    -- \todo This could be used for spawning also (spawn from "behind the player")
    --       (also need to check the Y in that case, same as in prev. loop)
    while true do
        -- \note We need to check the *next* object, because the current object
        --       is always outside the view.
        nextObjectIndex = oppositeEdge.objectIndex + step
        local object = readFunction( nextObjectIndex )
        -- \note "left" as in "leave"
        local leftView = oppositeCompareFunction( object[ element ],
                                                  oppositeEdge.position )
        if leftView then
            -- \note Use nextObjectIndex for spawn!
            oppositeEdge.objectIndex = oppositeEdge.objectIndex + step
        else
            break
        end
    end
end

local function scan( readFunction, step, element, compare, position )
    local start, end_
    if step < 0 then
        start = MapData.numObjects()-1
        end_  = 0
    else
        start = 0
        end_  = MapData.numObjects()-1
    end

    for i = start, end_, step do
        local object = readFunction( i )
        if compare( object[ element ], position ) then
            return i
        end
    end
end

local function initializeEdge( edgeId, position )
    -- Scan the object list to find the index that matches position.
    -- Basically find the first object in all directions, that falls outside
    -- the view.
    local objectIndex
    if edgeId == kEdgeLeft then
        objectIndex = scan( MapData.readObjectXSorted, -1, "x",
                            function( a, b ) return a < b end, position )
    elseif edgeId == kEdgeRight then
        objectIndex = scan( MapData.readObjectXSorted, 1, "x",
                            function( a, b ) return a > b end, position )
    elseif edgeId == kEdgeTop then
        objectIndex = scan( MapData.readObjectYSorted, -1, "y",
                            function( a, b ) return a < b end, position )
    elseif edgeId == kEdgeBottom then
        objectIndex = scan( MapData.readObjectYSorted, 1, "y",
                            function( a, b ) return a > b end, position )
    end

    return {
        position    = position,
        edgeId      = edgeId,
        objectIndex = objectIndex
    }
end

local function setPosition( x, y )
    -- \note Position is kept in world coordinates.
    -- \note The position is that of the top left point of the view.

    edgeLeft   = initializeEdge( kEdgeLeft,   x )
    edgeRight  = initializeEdge( kEdgeRight,  x + MapData.kViewWidth-1 + 2*kViewSlackX )
    edgeTop    = initializeEdge( kEdgeTop,    y )
    edgeBottom = initializeEdge( kEdgeBottom, y + MapData.kViewHeight-1 + 2*kViewSlackY )
end

function ObjectSpawner.setPosition()
    local positionAddr = SYM.__ngin_ObjectSpawner_setPosition_position[ 1 ]
    local x = ngin.read16( positionAddr + 0 )
    local y = ngin.read16( positionAddr + 2 )
    setPosition( x, y )
end

function ObjectSpawner.scrollHorizontal()
    local amount = ngin.signedByte( RAM.__ngin_ObjectSpawner_scrollHorizontal_amount )

    if amount < 0 then
        scroll( amount, edgeLeft, edgeRight, edgeTop, edgeBottom )
    elseif amount > 0 then
        scroll( amount, edgeRight, edgeLeft, edgeTop, edgeBottom )
    end
end

function ObjectSpawner.scrollVertical()
    local amount = ngin.signedByte( RAM.__ngin_ObjectSpawner_scrollVertical_amount )

    if amount < 0 then
        scroll( amount, edgeTop, edgeBottom, edgeLeft, edgeRight )
    elseif amount > 0 then
        scroll( amount, edgeBottom, edgeTop, edgeLeft, edgeRight )
    end
end

function ObjectSpawner.resetSpawn()
    local index = RAM.__ngin_ObjectSpawner_resetSpawn_index

    -- If index is ngin_ObjectSpawner_kInvalidSpawnIndex, this is a no-op.
    -- Thus, this function can be called without caring about whether the object
    -- was spawned by ObjectSpawner or manually.
    -- \todo Test this
    if index == kInvalidSpawnIndex then
        return
    end

    setObjectNotSpawned( index )
end

ngin.ObjectSpawner = ObjectSpawner
