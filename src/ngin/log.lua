function ngin.log( severity, message, ... )
    print( string.format( "[ngin] [%5s] ", severity ) ..
           string.format( message, ... )
    )
end
