ngin = {}

-- If the symbol DEBUG is defined anywhere in the project, assume debug
-- mode.
-- \todo Maybe NGIN_DEBUG or something would be better to avoid accidents
--       in user code.
ngin.DEBUG = SYM.DEBUG ~= nil

print( string.format( "[ngin] Running reset code (mode: %s)",
    ngin.DEBUG and "Debug" or "Release" )
)

ngin.ui = require( "ui" )
ngin.DebugDraw = require( "debug-draw" )

---------------------------------------------------------------------------

-- Convert an unsigned byte to a signed number.
-- \todo Move utility functions to another file, require() it.
function ngin.signed8( value )
    if value <= 127 then
        return value
    end
    return value - 256
end

function ngin.signed16( value )
    if value <= 32767 then
        return value
    end
    return value - 65536
end

-- Reads a 16-bit value from RAM.
function ngin.read16( addr )
    return bit32.bor(
        bit32.lshift( NDX.readMemory( addr+1 ), 8 ),
        NDX.readMemory( addr+0 )
    )
end

-- Write a 16-bit value to RAM.
function ngin.write16( addr, value )
    RAM[ addr+0 ] = bit32.band( value, 0xFF )
    RAM[ addr+1 ] = bit32.band( bit32.rshift( value, 8 ), 0xFF )
end

---------------------------------------------------------------------------

NDX.setAfterFrameHook( function()
    if ngin.DEBUG then
        if ngin.ui.toggleDebugDraw.VALUE == "ON" then
            return ngin.DebugDraw.render()
        end
    end
end )
