# This tool extracts metasprites from a Nintendulator PPU dump.
# The 8x8/8x16 sprites have to be connected for them to be grouped into a
# metasprite.
# The tool cannot detect whether 8x8 or 8x16 sprites have been used, so this
# has to be specified manually.
# This is not an efficient way to do this, but works OK because of the small
# maximum number of sprites (64).

# Nintendulator PPU dump format:
# - CHR: 8 KB
# - Nametables: 4x 1 KB
# - Sprites: 256 bytes
# - Palette: 32 bytes

kSpriteTemplate = """\
        ngin_SpriteRenderer_sprite {:4}, {:4}, {:4}, {}
"""

kTerminatorTemplate = """\
    ngin_SpriteRenderer_endMetasprite
.endproc

"""

def main( filename, outputFilenamePrefix, spriteSize, extrude ):
    f = open( filename, "rb" )
    chr = f.read( 8*1024 )
    f.seek( 4*1024, 1 )
    rawSprites = f.read( 256 )
    palette = f.read( 32 )

    def positionToRect( position ):
        return {
            "x1": position[ 0 ] - extrude,
            "x2": position[ 0 ] + spriteSize[ 0 ] + extrude,
            "y1": position[ 1 ] - extrude,
            "y2": position[ 1 ] + spriteSize[ 1 ] + extrude
        }

    # Overlap test, right/bottom side is inclusive.
    def isConnected( rect1, rect2 ):
        return rect1[ "x1" ] <= rect2[ "x2" ] and \
               rect1[ "x2" ] >= rect2[ "x1" ] and \
               rect1[ "y1" ] <= rect2[ "y2" ] and \
               rect1[ "y2" ] >= rect2[ "y1" ]

    # Gather all sprites.
    sprites = []
    for i in range( 64 ):
        y = ord( rawSprites[ 4*i + 0 ] )

        # If not visible, skip the sprite.
        if y >= 239:
            continue

        tile = ord( rawSprites[ 4*i + 1 ] )
        attr = ord( rawSprites[ 4*i + 2 ] )
        x    = ord( rawSprites[ 4*i + 3 ] )

        position = ( x, y )
        sprite = {
            "position": ( x, y ),
            "tile": tile,
            "attributes": attr,
            "rect": positionToRect( position ),
            "hasGroup": False
        }

        # print sprite
        sprites.append( sprite )

    groups = []
    def groupSprite( sprite, groupId ):
        groups[ groupId ].append( sprite )
        sprite[ "hasGroup" ] = True
        for sprite2 in sprites:
            if sprite2 == sprite:
                continue

            if sprite2[ "hasGroup" ]:
                continue

            if isConnected( sprite[ "rect" ], sprite2[ "rect" ] ):
                groupSprite( sprite2, groupId )

    groupId = 0
    for sprite in sprites:
        if not sprite[ "hasGroup" ]:
            groups.append( [] )
            groupSprite( sprite, groupId )
            groupId += 1

    metaspriteFile = open( outputFilenamePrefix + "-metasprites.inc", "w" )

    def boundingRectForGroup( group ):
        kBigNumber = 1000 # yolo
        minX, maxX = kBigNumber, -kBigNumber
        minY, maxY = kBigNumber, -kBigNumber
        for sprite in group:
            rect = sprite[ "rect" ]
            minX = min( minX, rect[ "x1"] )
            maxX = max( maxX, rect[ "x2"] )
            minY = min( minY, rect[ "y1"] )
            maxY = max( maxY, rect[ "y2"] )

        return {
            "x1": minX, "x2": maxX,
            "y1": minY, "y2": maxY
        }

    # Generate metasprites from the connected areas.
    for groupIndex, group in enumerate( groups ):
        metaspriteText = ".proc metasprite{}\n".format( groupIndex )

        metaspriteText += "    ngin_SpriteRenderer_metasprite\n"

        boundingRect = boundingRectForGroup( group )
        adjustX = -( boundingRect[ "x1" ] + boundingRect[ "x2" ] ) / 2
        adjustY = -( boundingRect[ "y1" ] + boundingRect[ "y2" ] ) / 2

        for sprite in group:
            x = sprite[ "position" ][ 0 ]
            y = sprite[ "position" ][ 1 ]
            x += adjustX
            y += adjustY
            spriteText = kSpriteTemplate.format( x, y,
                                                 sprite[ "tile" ],
                                                 sprite[ "attributes" ] )
            metaspriteText += spriteText

        metaspriteText += kTerminatorTemplate
        # print metaspriteText
        metaspriteFile.write( metaspriteText )

    # \todo Clean out unused data from the CHR.

    # Write the CHR data.
    open( outputFilenamePrefix + "-tiles.chr", "wb" ).write( chr )

    # Write the palette data.
    open( outputFilenamePrefix + "-palette.pal", "wb" ).write( palette )

    print "{} sprites extracted".format( groupId )

import sys
main( sys.argv[1], sys.argv[2], spriteSize=( 8, 16 ), extrude=0 )
