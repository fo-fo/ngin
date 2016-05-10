def packNesTile( tile ):
    assert len( tile ) % 64 == 0

    allTiles = ""

    # Can pack multiple tiles at the same time.
    for tileBase in xrange( 0, len( tile ), 64 ):
        # Pack a pixel/byte format 8x8px tile into 2bpp format: 64 bytes -> 16 bytes
        bitplane0All = ""
        bitplane1All = ""
        for y in xrange( 8 ):
            # Two bytes are generated from each tile row.
            bitplane0, bitplane1 = 0, 0
            baseOffset = 8*y
            for x in xrange( 8 ):
                pixel = ord( tile[ tileBase+baseOffset+x ] )
                assert pixel == pixel & 0b11
                bitplane0 = ( bitplane0 << 1 ) | ( pixel & 0b1 )
                bitplane1 = ( bitplane1 << 1 ) | ( ( pixel & 0b10 ) >> 1 )
            bitplane0All += chr( bitplane0 )
            bitplane1All += chr( bitplane1 )

        allTiles += bitplane0All + bitplane1All

    return allTiles

def listToString( list, width=3 ):
    return ", ".join( map( lambda x: "{:{width}}".format( x, width=width ), list ) )

def writeByteArray( f, indentText, list, bytesPerLine=8 ):
    f.write( indentText )
    numLines = ( len( list ) + bytesPerLine-1 ) / bytesPerLine
    for i in xrange( numLines ):
        start = i*bytesPerLine
        end = start + bytesPerLine
        sliced = list[ start:end ]
        if i != 0:
            f.write( " " * len( indentText ) )
        f.write( ".byte " + listToString( sliced ) + "\n" )
    if numLines == 0: f.write( "\n" )
