# This tool imports Ngin metasprites from image files.

# NOTE: Requires Pillow: https://python-pillow.github.io/

# \todo Add vertical/horizontal flipping of sprites when possible.
# \todo Import from Aseprite JSON. Can convert ASE->JSON+PNG with Aseprite
#       CLI tools.
# \todo Have an option for adjusting the cropping. Might produce better results
#       in some cases because the sprite allocation depends on the crop.

import argparse
from PIL import Image
import uuid
import os
import sys
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)),
                             "..", "common"))
import common

class HardwareSpriteSize:
    k8x8, k8x16 = 0, 1

class SpriteFlip:
    kHorizontal, kVertical, kHorizontalAndVertical = 0, 1, 2

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

def importSprites( infiles, gridSize, hardwareSpriteSize ):
    resultTiles = []
    uniqueResultTiles = {}
    allAnimationFrames = []

    def importImage( infile, gridSize, hardwareSpriteSize ):
        pilImage = Image.open( infile.file )

        # If grid size (width/height) hasn't been specified, use the image size.
        # Either of the width/height can be omitted.
        if gridSize[0] is None:
            gridSize = ( pilImage.size[0], gridSize[1] )
        if gridSize[1] is None:
            gridSize = ( gridSize[0], pilImage.size[1] )

        # Make sure that the image size is a multiple of the grid size.
        assert pilImage.size[0] % gridSize[0] == 0
        assert pilImage.size[1] % gridSize[1] == 0

        if hardwareSpriteSize == HardwareSpriteSize.k8x8:
            spriteSize = ( 8, 8 )
        elif hardwareSpriteSize == HardwareSpriteSize.k8x16:
            spriteSize = ( 8, 16 )
        else:
            assert False

        resultSprites = []
        animationFrames = []

        # ---------------------------------------------------------------------

        def importSpriteLayer( image, layer ):
            # Create a copy of the image, because we will be modifying it.
            pilImageLayer = image.copy()

            # Origin at the center of the image. This allows easy adjustment of the
            # origin in an image editor by moving the image.
            # If the size is an odd number, origin is at the center line.
            # E.g. if size is 3, origin is at line 1 (out of 0, 1, 2).
            # For even sizes, origin is at the topmost even scanline.
            # E.g. if size is 4, origin is also at line 1 (out of 0, 1, 2, 3).
            offsetX = -( ( pilImageLayer.size[ 0 ] - 1 ) // 2 )
            offsetY = -( ( pilImageLayer.size[ 1 ] - 1 ) // 2 )

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
                        sx, sy, uniqueResultTiles[ rawTile ], [ layer ]
                    ) )

        # ---------------------------------------------------------------------

        # Import all frames of an animation (either from a grid, or from
        # the file format itself, e.g. GIF).
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
                    # Import the layer, put results in "resultSprites" list.
                    kNumSpritePalettes = 4
                    for layer in range( kNumSpritePalettes ):
                        importSpriteLayer( animationFrame, layer )

                    animationFrames.append( resultSprites )

            # Try to seek to the next frame (for GIF, etc). EOFError is raised when
            # there are no more frames. This will also work for PNG -- EOFError is
            # raised on the first frame.
            # \note Depending on grid size, multiple frames may be extracted from
            #       a single animation frame.
            try:
                pilImage.seek( pilImage.tell() + 1 )
            except EOFError:
                break

        return infile.symbol, animationFrames

    def flipImage( symbol, frames, horizontalFlip, verticalFlip, hardwareSpriteSize ):
        assert horizontalFlip or verticalFlip

        newSymbol = symbol + "_"
        if horizontalFlip: newSymbol += "H"
        if verticalFlip:   newSymbol += "V"

        newFrames = []
        for frame in frames:
            newFrame = []
            for sprite in frame:
                newX, newY = sprite.x, sprite.y
                newAttributes = list( sprite.attributes )

                # \todo If the sprite is already flipped (from tile
                #       optimization), we should undo the flip here. Could use
                #       XOR for that...
                if horizontalFlip:
                    # 6 is magic. Don't question it.
                    newX = -newX - 6
                    newAttributes.append( "ppu::oam::kFlipHorizontal" )

                if verticalFlip:
                    newY = -newY - 6
                    if hardwareSpriteSize == HardwareSpriteSize.k8x16:
                        newY -= 8
                    newAttributes.append( "ppu::oam::kFlipVertical" )

                newFrame.append( Sprite(
                    newX, newY, sprite.tile, newAttributes
                ) )

            newFrames.append( newFrame )

        return newSymbol, newFrames

    for infile in infiles:
        symbol, frames = importImage( infile, gridSize, hardwareSpriteSize )
        allAnimationFrames.append( ( symbol, frames ) )

        if SpriteFlip.kHorizontal in infile.options:
            allAnimationFrames.append(
                flipImage( symbol, frames, True, False, hardwareSpriteSize ) )
        if SpriteFlip.kVertical in infile.options:
            allAnimationFrames.append(
                flipImage( symbol, frames, False, True, hardwareSpriteSize ) )
        if SpriteFlip.kHorizontalAndVertical in infile.options:
            allAnimationFrames.append(
                flipImage( symbol, frames, True, True, hardwareSpriteSize ) )

    return allAnimationFrames, resultTiles

def writeData( outPrefix, allAnimationFrames, tiles, hardwareSpriteSize ):
    with open( outPrefix + ".s", "w" ) as f:
        f.write( "; Data generated by Ngin sprite-importer.py\n\n" )

        outPrefixBase = os.path.basename( outPrefix )
        f.write( '.include "{}.inc"\n'.format( outPrefixBase ) )
        f.write( '.include "ngin/ngin.inc"\n\n' )

        f.write( 'ngin_pushSeg "CHR_ROM"\n' )
        f.write( ".proc chrData\n" )

        # Need to align to two tiles for 8x16
        if hardwareSpriteSize == HardwareSpriteSize.k8x16:
            f.write( "    .align ppu::kBytesPer8x16Tile\n" )

        f.write( '    .incbin "{}.chr"\n'.format( outPrefixBase ) )
        f.write( ".endproc\n" )
        f.write( "ngin_popSeg\n\n" )

        f.write( 'ngin_pushSeg "RODATA"\n\n' )

        if hardwareSpriteSize == HardwareSpriteSize.k8x16:
            f.write( ".define _8x16Tile( t ) ( ( ( (t) << 1 ) & $FF ) "+\
                     " | ( ( (t) >> 7 ) & 1 ) )\n\n" )

        # \todo Have to be able to specify animation speed from command line
        #       arg (can also be specified per frame, if coming from JSON)
        kDelay = 5

        for symbol, animationFrames in allAnimationFrames:
            for frameIndex, frame in enumerate( animationFrames ):
                f.write( ".proc {}_{}\n".format( symbol, frameIndex ) )

                if hardwareSpriteSize == HardwareSpriteSize.k8x16:
                    f.write( "    B = .lobyte( chrData/ppu::kBytesPer8x16Tile )\n" )
                else:
                    f.write( "    B = .lobyte( chrData/ppu::kBytesPer8x8Tile )\n" )

                # \todo Allow loop point to be specified.
                nextFrameIndex = ( frameIndex + 1 ) % len( animationFrames )
                f.write( "    ngin_SpriteRenderer_metasprite {:4}, {}_{}\n".format(
                    kDelay, symbol, nextFrameIndex
                ) )

                for sprite in frame:
                    tile = None
                    if hardwareSpriteSize == HardwareSpriteSize.k8x16:
                        tile = "_8x16Tile B+{}".format( sprite.tile )
                    else:
                        tile = "B+{}".format( sprite.tile )

                    attributes = "|".join( map( str, sprite.attributes ) )

                    f.write( ( "        ngin_SpriteRenderer_sprite " + \
                        "{:4}, {:4}, {}, {:3}\n" ).format( sprite.x, sprite.y,
                                                           tile, attributes
                    ) )

                f.write( "    ngin_SpriteRenderer_endMetasprite\n" )
                f.write( ".endproc\n\n" )

            # Duplicate symbol to point to the first frame.
            f.write( "{} := {}_{}\n\n".format( symbol, symbol, 0 ) )

        f.write( "ngin_popSeg\n\n" )

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

        for symbol, animationFrames in allAnimationFrames:
            for frameIndex, frame in enumerate( animationFrames ):
                f.write( ".global {}_{}\n".format( symbol, frameIndex ) )
            f.write( ".global {}\n".format( symbol ) )

        f.write( "\n.endif\n" )

class SymbolArg( object ):
    def __init__( self, symbol ):
        self.symbol = symbol

class InfileArg( object ):
    def __init__( self, infile ):
        self.infile = infile

class Infile( object ):
    def __init__( self, file, symbol, options ):
        self.file       = file
        self.symbol     = symbol
        # No duplicates allowed in options.
        self.options    = set( options )

def main():
    argParser = argparse.ArgumentParser(
        description="Import sprites from images into Ngin" )

    argParser.add_argument( "--hflip", dest="infiles", action="append_const",
                            help="generate a horizontally flipped variant",
                            const=SpriteFlip.kHorizontal )
    argParser.add_argument( "--vflip", dest="infiles", action="append_const",
                            help="generate a vertically flipped variant",
                            const=SpriteFlip.kVertical )
    argParser.add_argument( "--hvflip", dest="infiles", action="append_const",
                            help="generate a horizontally and vertically flipped variant",
                            const=SpriteFlip.kHorizontalAndVertical )

    argParser.add_argument( "-i", "--infile", dest="infiles", action="append",
                            type=InfileArg, metavar="FILE", required=True )
    argParser.add_argument( "-s", "--symbol", dest="infiles", action="append",
                            type=SymbolArg, metavar="SYMBOL", required=True )

    argParser.add_argument( "-o", "--outprefix", required=True,
        help="prefix for output files", metavar="PREFIX" )

    # \todo Grid size should be a per-sprite option...
    #       Should 8x16 be per-sprite as well? (Pros: more flexible, cons:
    #       can be annoying to define for each sprite separately, because in
    #       most cases want to use only one h/w sprite size)
    argParser.add_argument( "-x", "--gridwidth", type=int,
        help="sprite grid width", metavar="WIDTH" )
    argParser.add_argument( "-y", "--gridheight", type=int,
        help="sprite grid height", metavar="HEIGHT" )
    argParser.add_argument( "--8x16", action="store_const",
        const=HardwareSpriteSize.k8x16, default=HardwareSpriteSize.k8x8,
        help="use 8x16px hardware sprites (default: 8x8px)" )

    args = argParser.parse_args()

    # Gather the input files and their options from the command arguments.
    gatheredInfiles = []
    currentSymbol   = None
    currentOptions  = []
    for entry in args.infiles:
        if isinstance( entry, ( int, long ) ):
            currentOptions.append( entry )
        elif isinstance( entry, SymbolArg ):
            currentSymbol = entry.symbol
        elif isinstance( entry, InfileArg ):
            gatheredInfiles.append( Infile(
                entry.infile, currentSymbol, currentOptions
            ) )
            # Clear options on each file.
            currentOptions = []

    hardwareSpriteSize = getattr( args, "8x16" )

    allAnimationFrames, tiles = importSprites( gatheredInfiles,
        ( args.gridwidth, args.gridheight ), hardwareSpriteSize )

    writeData( args.outprefix, allAnimationFrames, tiles,
               hardwareSpriteSize )

main()
