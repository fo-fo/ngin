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
