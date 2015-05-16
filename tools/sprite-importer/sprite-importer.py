# This tool imports Ngin metasprites from image files.

# NOTE: Requires Python Imaging Library: http://www.pythonware.com/products/pil/

# \todo Add vertical/horizontal flipping of sprites when possible.
# \todo Add an option to generate a flipped metasprite (+ animation)
# \todo Import from Aseprite JSON. Can convert ASE->JSON+PNG with Aseprite
#       CLI tools.
# \todo Have an option for adjusting the cropping. Might produce better results
#       in some cases because the sprite allocation depends on the crop.

import argparse
import Image
import uuid
import os
import sys
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)),
                             "..", "common"))
import common

kHardwareSpriteSize8x8, kHardwareSpriteSize8x16 = 0, 1

class Sprite( object ):
    def __init__( self, x, y, tile, attributes ):
        self.x = x
        self.y = y
        self.tile = tile
        self.attributes = attributes

# Crops an image to minimum size. Returns the left-top and right-bottom
# coordinates of the cropped image. The right-bottom coordinates are exclusive.
def croppedRect( pilImage ):
    pixels = pilImage.load()

    # For each side, the first pixel row/column that should be included
    # in the cropped image.
    cropTop, cropLeft, cropBottom, cropRight = None, None, None, None

    # Scan vertically.
    for y in xrange( pilImage.size[ 1 ] ):
        yBottom = pilImage.size[ 1 ]-1 - y
        for x in xrange( pilImage.size[ 0 ] ):
            if cropTop is None and pixels[ x, y ] != 0:
                cropTop = y
            if cropBottom is None and pixels[ x, yBottom ] != 0:
                cropBottom = yBottom
            if cropTop is not None and cropBottom is not None:
                break

    # Scan horizontally.
    for x in xrange( pilImage.size[ 0 ] ):
        xRight = pilImage.size[ 0 ]-1 - x
        for y in xrange( pilImage.size[ 1 ] ):
            if cropLeft is None and pixels[ x, y ] != 0:
                cropLeft = x
            if cropRight is None and pixels[ xRight, y ] != 0:
                cropRight = xRight
            if cropLeft is not None and cropRight is not None:
                break

    # \note If one of cropXXX is None, all must be None.
    if cropLeft is None:
        # Return an empty rectangle.
        return ( 0, 0 ), ( 0, 0 )

    return ( cropLeft, cropTop ), ( cropRight+1, cropBottom+1 )

def importSprites( infile, gridSize, hardwareSpriteSize ):
    pilImage = Image.open( infile )

    # If grid size (width/height) hasn't been specified, use the image size.
    # Either of the width/height can be omitted.
    if gridSize[0] is None:
        gridSize = ( pilImage.size[0], gridSize[1] )
    if gridSize[1] is None:
        gridSize = ( gridSize[0], pilImage.size[1] )

    # Make sure that the image size is a multiple of the grid size.
    assert pilImage.size[0] % gridSize[0] == 0
    assert pilImage.size[1] % gridSize[1] == 0

    if hardwareSpriteSize == kHardwareSpriteSize8x8:
        spriteSize = ( 8, 8 )
    elif hardwareSpriteSize == kHardwareSpriteSize8x16:
        spriteSize = ( 8, 16 )
    else:
        assert False

    resultTiles = []
    uniqueResultTiles = {}
    resultSprites = []

    def importSpriteLayer( image, layer ):
        # Create a copy of the image, because we will be modifying it.
        pilImageLayer = image.copy()

        # Origin at the center of the image. This allows easy adjustment of the
        # origin in an image editor by moving the image.
        offsetX = -( pilImageLayer.size[ 0 ] // 2 )
        offsetY = -( pilImageLayer.size[ 1 ] // 2 )

        # \todo Might want to treat the transparent index from the image in a
        #       special way (currently every 4th is transparent)

        # Split the image into palette layers based on indexed colors.
        # First 4 colors are palette 0, the next 4 form palette 1, and so on.
        # Every 4th color is considered transparent.
        pixels = pilImageLayer.load()

        # Mask out (to 0) the colors that don't belong to the current layer.
        # \todo There are other options for the replacement color in case two
        #       sprite layers have overlapping non-transparent colors. To
        #       minimize flicker, it might be better to fill with the closest
        #       matching color from the current palette (make it configurable?).
        #       It also affects tile uniqueness optimization.
        for y in xrange( pilImageLayer.size[ 1 ] ):
            for x in xrange( pilImageLayer.size[ 0 ] ):
                pixelLayer = ( pixels[ x, y ] & 0b1100 ) >> 2
                if pixelLayer != layer:
                    # Clear to transparent if layer doesn't match.
                    pixels[ x, y ] = 0
                else:
                    # Clear the palette set index if layer does match.
                    pixels[ x, y ] &= 0b11

        # Crop the image vertically only. Each 8/16 rows will get individually
        # cropped horizontally later on.
        cropLeftTop, cropRightBottom = croppedRect( pilImageLayer )
        pilImageLayer = pilImageLayer.crop( (
            # Left, Top, Right, Bottom
            0, cropLeftTop[ 1 ],
            pilImageLayer.size[ 0 ], cropRightBottom[ 1 ]
        ) )


        # If cropped to empty, skip the layer.
        if pilImageLayer.size[ 0 ] == 0 or pilImageLayer.size[ 1 ] == 0:
            return

        kEmptyTile = chr( 0 ) * spriteSize[ 0 ] * spriteSize[ 1 ]

        for y in xrange( 0, pilImageLayer.size[ 1 ], spriteSize[ 1 ] ):
            # Grab the slice of the image.
            slice = pilImageLayer.crop( (
                0, y,
                pilImageLayer.size[ 0 ], y + spriteSize[ 1 ]
            ) )
            sliceCropLeftTop, sliceCropRightBottom = croppedRect( slice )

            # Crop the sliced image.
            slice = slice.crop( (
                sliceCropLeftTop[0],     sliceCropLeftTop[1],
                sliceCropRightBottom[0], sliceCropRightBottom[1]
            ) )

            # Iterate horizontally over the sliced image.
            for x in xrange( 0, slice.size[ 0 ], spriteSize[ 0 ] ):
                spriteTile = slice.crop( (
                    x, 0,
                    x + spriteSize[ 0 ], spriteSize[ 1 ]
                ) )
                rawTile = spriteTile.tostring()
                # Shouldn't be able to be empty at this point.
                # (If it can, we could skip it.)
                assert rawTile != kEmptyTile

                # Add the tile (remove duplicates)
                # \todo Can remove duplicates in case of horizontal/vertical
                #       mirrors as well.
                if rawTile not in uniqueResultTiles:
                    uniqueResultTiles[ rawTile ] = len( uniqueResultTiles )
                    resultTiles.append( rawTile )

                sx = sliceCropLeftTop[ 0 ] + x + offsetX
                sy = cropLeftTop[ 1 ] + sliceCropLeftTop[ 1 ] + y + offsetY
                resultSprites.append( Sprite(
                    sx, sy, uniqueResultTiles[ rawTile ], layer
                ) )

    allFrames = []

    while True:
        # \note Should be optional whether the animation frame tiles are
        #       optimized globally, or per frame. For now it's global.
        for y in xrange( 0, pilImage.size[ 1 ], gridSize[ 1 ] ):
            for x in xrange( 0, pilImage.size[ 0 ], gridSize[ 0 ] ):
                animationFrame = pilImage.crop( (
                    x, y,
                    x + gridSize[ 0 ], y + gridSize[ 1 ]
                ) )

                # A new set of sprites is generated for each frame.
                resultSprites = []

                # 4 layers, one for each 4-color sprite palette
                kNumSpritePalettes = 4
                for layer in range( kNumSpritePalettes ):
                    importSpriteLayer( animationFrame, layer )

                allFrames.append( resultSprites )

        # Try to seek to the next frame (for GIF, etc). EOFError is raised when
        # there are no more frames. This will also work for PNG -- EOFError is
        # raised on the first frame.
        # \note Depending on grid size, multiple frames may be extracted from
        #       a single animation frame.
        try:
            pilImage.seek( pilImage.tell() + 1 )
        except EOFError:
            break

    return allFrames, resultTiles

def writeData( symbol, outPrefix, allFrames, tiles, hardwareSpriteSize ):
    with open( outPrefix + ".s", "w" ) as f:
        f.write( "; Data generated by Ngin sprite-importer.py\n\n" )

        outPrefixBase = os.path.basename( outPrefix )
        f.write( '.include "{}.inc"\n'.format( outPrefixBase ) )
        f.write( '.include "ngin/ngin.inc"\n\n' )

        f.write( 'ngin_pushSeg "CHR_ROM"\n' )
        f.write( ".proc chrData\n" )

        # Need to align to two tiles for 8x16
        if hardwareSpriteSize == kHardwareSpriteSize8x16:
            f.write( "    .align ppu::kBytesPer8x16Sprite\n" )

        f.write( '    .incbin "{}.chr"\n'.format( outPrefixBase ) )
        f.write( ".endproc\n" )
        f.write( "ngin_popSeg\n\n" )

        if hardwareSpriteSize == kHardwareSpriteSize8x16:
            f.write( ".define _8x16Tile( t ) ( ( ( (t) << 1 ) & $FF ) "+\
                     " | ( ( (t) >> 7 ) & 1 ) )\n\n" )

        # \todo Have to be able to specify animation speed from command line
        #       arg (can also be specified per frame, if coming from JSON)
        kDelay = 5

        # \todo Have ways for defining multiple animations (JSON from Aseprite,
        #       something else?)

        for frameIndex, frame in enumerate( allFrames ):
            f.write( ".proc {}_{}\n".format( symbol, frameIndex ) )

            if hardwareSpriteSize == kHardwareSpriteSize8x16:
                f.write( "    B = .lobyte( chrData/ppu::kBytesPer8x16Sprite )\n" )
            else:
                f.write( "    B = .lobyte( chrData/ppu::kBytesPer8x8Sprite )\n" )

            # \todo Allow loop point to be specified.
            nextFrameIndex = ( frameIndex + 1 ) % len( allFrames )
            f.write( "    ngin_SpriteRenderer_metasprite {:4}, {}_{}\n".format(
                kDelay, symbol, nextFrameIndex
            ) )

            for sprite in frame:
                tile = None
                if hardwareSpriteSize == kHardwareSpriteSize8x16:
                    tile = "_8x16Tile B+{}".format( sprite.tile )
                else:
                    tile = "B+{}".format( sprite.tile )

                f.write( ( "        ngin_SpriteRenderer_sprite " + \
                    "{:4}, {:4}, {}, {:3}\n" ).format( sprite.x, sprite.y, tile,
                                                       sprite.attributes
                ) )

            f.write( "    ngin_SpriteRenderer_endMetasprite\n" )
            f.write( ".endproc\n\n" )

        # Duplicate symbol to point to the first frame.
        f.write( "{} := {}_{}\n".format( symbol, symbol, 0 ) )

    with open( outPrefix + ".chr", "wb" ) as f:
        for tile in tiles:
            packed = common.packNesTile( tile )
            f.write( packed )

    with open( outPrefix + ".inc", "w" ) as f:
        uniqueSymbol = "NGIN_SPRITE_IMPORTER_" + \
                       str( uuid.uuid4() ).upper().replace( "-", "_" )
        f.write( ".if .not .defined( {} )\n".format( uniqueSymbol ) )
        f.write( "{} = 1\n\n".format( uniqueSymbol ) )
        f.write( '.include "ngin/ngin.inc"\n\n' )
        for frameIndex, frame in enumerate( allFrames ):
            f.write( ".global {}_{}\n".format( symbol, frameIndex ) )
        f.write( ".global {}\n".format( symbol ) )
        f.write( "\n.endif\n" )

def main():
    argParser = argparse.ArgumentParser(
        description="Import sprites from images into Ngin" )
    argParser.add_argument( "-i", "--infile", required=True )
    argParser.add_argument( "-s", "--symbol", required=True )
    argParser.add_argument( "-o", "--outprefix", required=True,
        help="prefix for output files" )
    argParser.add_argument( "-x", "--gridwidth", type=int,
        help="sprite grid width" )
    argParser.add_argument( "-y", "--gridheight", type=int,
        help="sprite grid height" )
    argParser.add_argument( "--8x16", action="store_const",
        const=kHardwareSpriteSize8x16, default=kHardwareSpriteSize8x8,
        help="use 8x16px hardware sprites (default: 8x8px)" )

    args = argParser.parse_args()

    hardwareSpriteSize = getattr( args, "8x16" )

    allFrames, tiles = importSprites( args.infile,
        ( args.gridwidth, args.gridheight ), hardwareSpriteSize )

    writeData( args.symbol, args.outprefix, allFrames, tiles, hardwareSpriteSize )

main()
