# This tool converts map data from a flat array that uses 16x16px metatiles to
# the format used by ngin (256x256px metatiles of 32x32px metatiles of 16x16px
# metatiles).
#
# The format of the input binary map must be:
#   1 byte:  map width
#   1 byte:  map height
#   N bytes: map data (N = width*height)
#
# The output is ca65 source code.

# Splits a map into metatiles. Returns the new map and the new metatiles.
def metatileize( map, metatileSize ):
    # Make sure the width and height are a multiple of the metatile size.
    for row in map:
        while len( row ) % metatileSize[ 0 ] != 0:
            row.append( 0 )

    while len( map ) % metatileSize[ 1 ] != 0:
        map.append( [0] * len( map[ 0 ] ) )

    metatiles = {}
    newMap = []

    # Gather 32x32px metatiles.
    for y in range( 0, len( map ), metatileSize[ 1 ] ):
        newMapRow = []
        for x in range( 0, len( map[ y ] ), metatileSize[ 0 ] ):
            metatile = []
            for v in range( metatileSize[ 1] ):
                for u in range( metatileSize[ 0 ] ):
                    metatile.append( map[ y+v ][ x+u ] )
            metatile = tuple( metatile )
            # Add to list of metatiles, if not already there.
            if metatile not in metatiles:
                metatiles[ metatile ] = len( metatiles )
            newMapRow.append( metatiles[ metatile ] )
        newMap.append( newMapRow )

    return metatiles, newMap

def listToString( list ):
    return ", ".join( map( str, list ) )

def main( filename, outputFilename ):
    f = open( filename, "rb" )
    width  = ord( f.read( 1 ) )
    height = ord( f.read( 1 ) )
    data   = map( ord, f.read( width * height ) )

    print "Map width: {} height: {}".format( width, height )

    # Split the map into list of rows.
    mapRows = []
    for i in range( 0, len( data ), width ):
        mapRows.append( data[ i : i+width ] )

    # Get the 32x32px metatiles.
    metatiles32, map32 = metatileize( mapRows, ( 32/16, 32/16 ) )

    for row in map32:
        print row

    print "32x32px metatiles: {}".format( len( metatiles32 ) )

    if len( metatiles32 ) > 256:
        raise Exception( "over 256 32x32px metatiles produced" )

    # Get the 256x256px metatiles.
    metatiles256, map256 = metatileize( map32, ( 256/32, 256/32 ) )

    print "256x256px metatiles: {}".format( len( metatiles256 ) )

    if len( metatiles256 ) > 256:
        raise Exception( "over 256 256x256px metatiles produced" )

    # Generate the output.
    output = ""

    # Output the screen rows (256x256px metatile indices).
    for i, screenRow in enumerate( map256 ):
        output += "row{}: .byte ".format( i ) + \
                  listToString( screenRow ) + "\n"
    output += "\n"

    # Output the screens (256x256px metatiles).
    for screen, i in metatiles256.iteritems():
        output += "screen{}: .byte ".format( i ) + \
                  listToString( screen ) + "\n"
    output += "\n"

    kScreenRowPointersTemplate = """.scope screenRowPointers
    .define screenRowPointers_ {}
    lo: .lobytes screenRowPointers_
    hi: .hibytes screenRowPointers_
    .undefine screenRowPointers_
.endscope

"""

    output += kScreenRowPointersTemplate.format(
        ", ".join( map( lambda x: "row{}".format( x ),
                        range( len( map256 ) ) ) )
    )

    kScreenPointersTemplate = """.scope screenPointers
    .define screenPointers_ {}
    lo: .lobytes screenPointers_
    hi: .hibytes screenPointers_
    .undefine screenPointers_
.endscope

"""

    output += kScreenPointersTemplate.format(
        ", ".join( map( lambda x: "screen{}".format( x ),
                        range( len( metatiles256 ) ) ) )
    )

    # Deinterleave the 32x32 metatiles for output.
    metatiles32Deinterleaved = []
    for i in range( 4 ):
        metatiles32Deinterleaved.append( [0] * len( metatiles32 ) )
    for metatile32, j in metatiles32.iteritems():
        for i, value in enumerate( metatile32 ):
            metatiles32Deinterleaved[ i ][ j ] = value

    kMetatiles32Template = """.scope _32x32Metatiles
    topLeft:     .byte {}
    topRight:    .byte {}
    bottomLeft:  .byte {}
    bottomRight: .byte {}
.endscope

"""

    output += kMetatiles32Template.format(
        listToString( metatiles32Deinterleaved[ 0 ] ),
        listToString( metatiles32Deinterleaved[ 1 ] ),
        listToString( metatiles32Deinterleaved[ 2 ] ),
        listToString( metatiles32Deinterleaved[ 3 ] )
    )

    # Output the data.
    outFile = open( outputFilename, "w" )
    outFile.write( output )

import sys
main( sys.argv[1], sys.argv[2] )
