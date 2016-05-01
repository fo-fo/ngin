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
    debugStrings[ #debugStrings + 1 ] = string.format( message, ... )
end

return DebugDraw
