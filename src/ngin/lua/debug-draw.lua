local DebugDraw = {}

-- \todo Query format in later NDX.
local kFormat = "283x240 -a"

local canvas1 = cd.CreateCanvas( cd.IMAGERGB, kFormat )
local canvas2 = cd.CreateCanvas( cd.IMAGERGB, kFormat )
for _, canvas in ipairs { canvas1, canvas2 } do
    canvas:SetBackground( cd.EncodeAlpha( cd.BLACK, 0 ) )
    canvas:Font( "Tahoma", cd.PLAIN, 7 )
end

-- Draw = the canvas the debug stuff is being drawn into
-- Render = the canvas that is being rendered on screen
local drawCanvas = canvas1
local renderCanvas = canvas2

local debugStrings

local function text( x, y, str )
    drawCanvas:SetForeground( cd.BLACK )
    drawCanvas:Text( x-1, y-1, str )
    drawCanvas:SetForeground( cd.WHITE )
    drawCanvas:Text( x, y, str )
end

local function finishDrawing()
    local str = table.concat( debugStrings, "\n" )
    -- GetTextBox doesn't seem to like empty strings (?)
    if str == "" then return end
    local x = 8
    local y = 222
    drawCanvas:SetForeground( cd.EncodeAlpha( cd.GREEN, 64 ) )
    local xMin, xMax, yMin, yMax = drawCanvas:GetTextBox( x, y, str )
    local kExpand = 3
    drawCanvas:Box( xMin-kExpand, xMax+kExpand, yMin-kExpand, yMax+kExpand )
    drawCanvas:SetForeground( cd.WHITE )
    text( x, y, str )
end

function DebugDraw.startFrame()
    drawCanvas:Activate()
    drawCanvas:Clear()

    debugStrings = {}
end

function DebugDraw.endFrame()
    finishDrawing()

    -- Swap the canvases.
    if drawCanvas == canvas1 then
        drawCanvas = canvas2; renderCanvas = canvas1
    else
        drawCanvas = canvas1; renderCanvas = canvas2
    end
end

function DebugDraw.render()
    return renderCanvas
end

function DebugDraw.printf( message, ... )
    if not ngin.DEBUG then return end

    debugStrings[ #debugStrings + 1 ] = string.format( message, ... )
end

local function unpackColor( color )
    return cd.EncodeAlpha( cd.EncodeColor(
        bit32.band( bit32.rshift( color, 24 ), 0xFF ),
        bit32.band( bit32.rshift( color, 16 ), 0xFF ),
        bit32.band( bit32.rshift( color,  8 ), 0xFF )
    ), bit32.band( color, 0xFF ) )
end

local function unpackVector2_16( vector )
    return bit32.band( vector, 0xFFFF ), bit32.rshift( vector, 16 )
end

local function adjustXy( x, y )
    -- Compensate for left border for X. Flip the Y axis.
    local _, canvasHeight = drawCanvas:GetSize()
    return x + 16 + ngin_cfg_DebugDraw_offsetX,
           ( canvasHeight - 1 ) - y + ngin_cfg_DebugDraw_offsetY
end

function DebugDraw.crossXy( x, y, color )
    x, y = adjustXy( x, y )
    local kSize = 2
    drawCanvas:Foreground( unpackColor( color ) )
    -- \todo canvas:Mark would do the same thing, but simpler.
    drawCanvas:Line( x-kSize, y-kSize, x+kSize, y+kSize )
    drawCanvas:Line( x-kSize, y+kSize, x+kSize, y-kSize )
end

function DebugDraw.cross( position, color )
    local x, y = unpackVector2_16( position )

    DebugDraw.crossXy( x, y, color )
end

function DebugDraw.rect( leftTop, rightBottom, color )
    local x1, y1 = unpackVector2_16( leftTop )
    local x2, y2 = unpackVector2_16( rightBottom )

    x1, y1 = adjustXy( x1, y1 )
    x2, y2 = adjustXy( x2, y2 )

    -- \note All coordinates are inclusive.
    drawCanvas:Foreground( unpackColor( color ) )
    drawCanvas:Rect( x1, x2, y1, y2 )
end

return DebugDraw
