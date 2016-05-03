function ngin.log( severity, message, ... )
    if not ngin.DEBUG then return end

    print( string.format( "[ngin] [%5s] ", severity ) ..
           string.format( message, ... )
    )
end
