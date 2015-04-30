print( "[ngin] Running reset code" )

ngin = {}

-- Convert an unsigned byte to a signed number.
-- \todo Move utility functions to another file, require() it.
function ngin.signedByte( value )
    if value <= 127 then
        return value
    end
    return value - 256
end

-- Reads a 16-bit value from RAM.
function ngin.read16( addr )
    return bit32.bor(
        bit32.lshift( NDX.readMemory( addr+1 ), 8 ),
        NDX.readMemory( addr+0 )
    )
end
