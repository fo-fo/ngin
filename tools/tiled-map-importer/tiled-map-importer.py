# This tool imports Tiled maps (.tmx) into a format usable by the engine.
# All of the maps that use the same tileset have to be specified at the same
# time, because all of the maps can affect the final tileset that is generated.

# NOTE: Requires Python Imaging Library: http://www.pythonware.com/products/pil/

# \todo Custom exception class, so we can differentiate between normalish errors
#       (with clean print), and unexpected errors.

import argparse
from xml.etree import cElementTree
import base64
import zlib
import struct
import os
import Image
import uuid
import sys
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)),
                             "..", "common"))
import common

# Zero indicates an empty tile.
kEmptyGid = 0

# The top 3 bits in global tile IDs contain flip flags.
kGidHorzFlip = 1<<31
kGidVertFlip = 1<<30
kGidDiagFlip = 1<<29
kGidFlagMask = kGidHorzFlip|kGidVertFlip|kGidDiagFlip

kSolidAttribute = "ngin_MapData_Attributes0::kSolid"

kScreenSizeX, kScreenSizeY = 256, 256
kMt32SizeX, kMt32SizeY = 32, 32
kMt16SizeX, kMt16SizeY = 16, 16
kTile8SizeX, kTile8SizeY = 8, 8

class Size( object ):
    def __init__( self, width, height ):
        self.width = width
        self.height = height

class NginMapData( object ):
    def __init__( self, map ):
        self.map = map
        # Size of the map in screen units
        self.sizeScreens = None
        # Markers placed in the map to indicate positions
        self.markers = []
        # Objects placed in the map. Not sorted in any way.
        self.objects = []

    def adjustXY( self ):
        adjustX = -0x8000 + kScreenSizeX * ( self.sizeScreens[0] // 2 )
        adjustY = -0x8000 + kScreenSizeY * ( self.sizeScreens[1] // 2 )
        return adjustX, adjustY

    # This function converts a point from the map's coordinate system
    # (with origin at the top left corner) to the world coordinate system of
    # Ngin (unsigned coordinates, origin at about the middle of the map).
    def mapPixelToNginWorldPoint( self, mapPixelPoint ):
        # \note This logic is duplicated in map-data.lua in the engine code.
        adjustX, adjustY = self.adjustXY()
        return (
            mapPixelPoint[0] - adjustX,
            mapPixelPoint[1] - adjustY
        )

    def nginWorldPointToMapPixel( self, nginWorldPoint ):
        adjustX, adjustY = self.adjustXY()
        return (
            nginWorldPoint[0] + adjustX,
            nginWorldPoint[1] + adjustY
        )

class NginCommonMapData( object ):
    def __init__( self ):
        # List of unique 8x8 tiles
        self.uniqueTiles = []
        # Dict to keep track of duplicates, and to provide mapping from tile->index.
        self.uniqueTileMap = {}

        # List of unique 16x16 metatiles
        self.uniqueMt16 = []
        self.uniqueMt16Map = {}

        # List of unique 32x32 metatiles
        self.uniqueMt32 = []
        self.uniqueMt32Map = {}

        # List of unique screens
        self.uniqueScreens = []
        self.uniqueScreenMap = {}

        # Maps (instances of NginMapData)
        # Not optimized for uniqueness since we don't expect to have the same
        # map multiple times. :)
        self.maps = []

    def addTile( self, tile ):
        if tile not in self.uniqueTileMap:
            self.uniqueTileMap[ tile ] = len( self.uniqueTiles )
            self.uniqueTiles.append( tile )

        return self.uniqueTileMap[ tile ]

    def addMt16( self, mt16 ):
        if mt16 not in self.uniqueMt16Map:
            self.uniqueMt16Map[ mt16 ] = len( self.uniqueMt16 )
            self.uniqueMt16.append( mt16 )

        return self.uniqueMt16Map[ mt16 ]

    def addMt32( self, mt32 ):
        if mt32 not in self.uniqueMt32Map:
            self.uniqueMt32Map[ mt32 ] = len( self.uniqueMt32 )
            self.uniqueMt32.append( mt32 )

        return self.uniqueMt32Map[ mt32 ]

    def addScreen( self, screen ):
        if screen not in self.uniqueScreenMap:
            self.uniqueScreenMap[ screen ] = len( self.uniqueScreens )
            self.uniqueScreens.append( screen )

        return self.uniqueScreenMap[ screen ]

    def addMap( self, map ):
        # Maps are not optimized for uniqueness (pointless).
        self.maps.append( map )
        return len( self.maps ) - 1

class Map( object ):
    def __init__( self, size, tileSize, tilesets, layers, objectLayers ):
        self.size = size
        self.tileSize = tileSize
        self.tilesets = tilesets
        self.layers = layers
        self.objectLayers = objectLayers

    def tilesetFromGid( self, gid ):
        # \note Tilesets are guaranteed to be ordered by firstGid.
        gid &= ~kGidFlagMask
        for tileset in reversed( self.tilesets ):
            if gid >= tileset.firstGid:
                return tileset

        assert False

    def pixelSize( self ):
        return (
            self.size.width  * self.tileSize.width,
            self.size.height * self.tileSize.height
        )

class Layer( object ):
    # \note In Qt Tiled, layer size is always equal to map size.
    def __init__( self, data, properties ):
        self.data = data
        self.properties = properties

class ObjectLayer( object ):
    def __init__( self, objects, properties ):
        self.objects = objects
        self.properties = properties

class Object( object ):
    def __init__( self, name, type, position, size ):
        self.name = name
        self.type = type
        self.position = position
        self.size = size

class Properties( object ):
    def __init__( self, properties ):
        self.properties = properties

    def getBool( self, name ):
        lowerName = name.lower()
        if lowerName not in self.properties:
            return None

        return self.properties[ lowerName ] == "true"

class Tileset( object ):
    def __init__( self, firstGid, image, tileSize, tiles, baseDir ):
        self.firstGid = firstGid
        self.image = image
        self.tileSize = tileSize
        self.tiles = tiles
        self.baseDir = baseDir

    def getTilePilImage( self, gid ):
        gidNoFlags = gid & ~kGidFlagMask
        assert gidNoFlags >= self.firstGid
        localId = gidNoFlags - self.firstGid
        tile = None
        tileTransparency = None
        # If a separate image exists for this tile, get it.
        if localId in self.tiles and self.tiles[ localId ].image is not None:
            image = self.tiles[ localId ].image
            tile = image.getPilImage( self.baseDir )
            tileTransparency = image.getPilImageTransparencyMask( self.baseDir )
        elif self.image is not None: # Otherwise get from the tileset image.
            leftTop = self.__leftTopFromLocalId( localId )
            tilesetImage = self.image.getPilImage( self.baseDir )
            transparencyImage = self.image.getPilImageTransparencyMask( self.baseDir )
            cropBox = (
                leftTop[ 0 ],
                leftTop[ 1 ],
                leftTop[ 0 ] + self.tileSize.width,
                leftTop[ 1 ] + self.tileSize.height,
            )
            # \note Crop is lazy, so shouldn't be overly costly.
            tile = tilesetImage.crop( cropBox )
            tileTransparency = transparencyImage.crop( cropBox )
        else:
            raise Exception( "i have no image" )

        # Apply flip/rotate flags from GID.
        if gid & kGidDiagFlip:
            tile = tile.transpose( Image.ROTATE_90 ).transpose(
                Image.FLIP_TOP_BOTTOM )
            tileTransparency = tileTransparency.transpose(
                Image.ROTATE_90 ).transpose( Image.FLIP_TOP_BOTTOM )
        if gid & kGidHorzFlip:
            tile = tile.transpose( Image.FLIP_LEFT_RIGHT )
            tileTransparency = tileTransparency.transpose(
                Image.FLIP_LEFT_RIGHT )
        if gid & kGidVertFlip:
            tile = tile.transpose( Image.FLIP_TOP_BOTTOM )
            tileTransparency = tileTransparency.transpose(
                Image.FLIP_TOP_BOTTOM )

        return tile, tileTransparency

    def __leftTopFromLocalId( self, localId ):
        # \note Tileset image size doesn't have to be a multiple of tile size.
        #       If it isn't, the extra pixels are ignored.
        tilesX = self.image.size.width / self.tileSize.width
        return (
            ( localId % tilesX ) * self.tileSize.width,
            ( localId / tilesX ) * self.tileSize.height
        )

    # \note May return None, since all of the tiles within the Tileset
    #       may not contain a <tile> entry. Only ones with properties do.
    def getTile( self, gid ):
        gid &= ~kGidFlagMask
        assert gid >= self.firstGid
        localId = gid - self.firstGid
        return self.tiles.get( localId )

class TilesetImage( object ):
    def __init__( self, source, size ):
        self.source = source
        self.size = size
        self.pilImage = None
        self.pilImageTransparencyMask = None
        self.transparencyKey = None

    def getPilImage( self, baseDir ):
        if self.pilImage is not None:
            return self.pilImage

        fullPath = os.path.join( baseDir, self.source )
        self.pilImage = Image.open( fullPath )
        # Image must be paletted.
        assert self.pilImage.mode == "P"
        # Get the color index that is used for transparency.
        self.transparencyKey = self.pilImage.info.get( "transparency" )

        return self.pilImage

    def getPilImageTransparencyMask( self, baseDir ):
        if self.pilImageTransparencyMask is not None:
            return self.pilImageTransparencyMask

        pilImage = self.getPilImage( baseDir )

        # Create a transparency mask based on the transparencyKey (if set).
        # In the mask, transparent pixels use color 0, opaque pixels use 255.
        result = Image.new( "L", pilImage.size )
        destPixels = result.load()
        srcPixels = pilImage.load()
        for y in xrange( pilImage.size[ 1 ] ):
            for x in xrange( pilImage.size[ 0 ] ):
                srcPixel = srcPixels[ x, y ]
                destPixels[ x, y ] = 255 if srcPixel != self.transparencyKey else 0

        self.pilImageTransparencyMask = result
        return result

class TilesetTile( object ):
    # \todo animation, ...
    def __init__( self, id, properties, image ):
        self.id = id
        self.properties = properties
        self.image = image

def unexpectedElem( event, elem ):
    return Exception( "unexpected tag '{}' (event '{}')".format( elem.tag,
                                                                 event ) )

def parseTmx( infile ):
    def parseProperty( propertyElem, iterator ):
        for event, elem in iterator:
            if event == "end" and elem.tag == "property":
                return (
                    elem.attrib[ "name" ],
                    elem.attrib[ "value" ]
                )
            else:
                raise unexpectedElem( event, elem )

    def parseProperties( propertiesElem, iterator ):
        properties = {}
        for event, elem in iterator:
            if event == "end" and elem.tag == "properties":
                return Properties( properties )
            elif event == "start" and elem.tag == "property":
                property = parseProperty( elem, iterator )
                properties[ property[ 0 ].lower() ] = property[ 1 ]
            else:
                raise unexpectedElem( event, elem )

    def parseLayerData( dataElem, iterator ):
        for event, elem in iterator:
            if event == "end" and elem.tag == "data":
                # \todo Support other encodings and compression modes.
                if not ( elem.attrib[ "encoding" ] == "base64" and \
                         elem.attrib[ "compression" ] == "zlib" ):
                    raise Exception( "unsupported encoding/compression" )

                decoded = base64.b64decode( elem.text )
                decompressed = zlib.decompress( decoded )
                # Unpack N/4 32-bit little-endian unsigned integers
                unpacked = struct.unpack( "<{}I".format(
                    len( decompressed ) / 4 ), decompressed )

                # \todo Verify that size of "unpacked" matches the layer
                #       size.
                return unpacked
            else:
                raise unexpectedElem( event, elem )

    def parseLayer( layerElem, iterator ):
        data = None
        properties = Properties( {} )
        for event, elem in iterator:
            if event == "end" and elem.tag == "layer":
                return Layer( data, properties )
            elif event == "start" and elem.tag == "data":
                data = parseLayerData( elem, iterator )
            elif event == "start" and elem.tag == "properties":
                properties = parseProperties( elem, iterator )
            else:
                raise unexpectedElem( event, elem )

    def parseObjectLayer( objectLayerElem, iterator ):
        objects = []
        properties = Properties( {} )
        for event, elem in iterator:
            if event == "end" and elem.tag == "objectgroup":
                return ObjectLayer( objects, properties )
            elif event == "start" and elem.tag == "object":
                objects.append( parseObject( elem, iterator ) )
            elif event == "start" and elem.tag == "properties":
                properties = parseProperties( elem, iterator )
            else:
                raise unexpectedElem( event, elem )

    def parseObject( objectElem, iterator ):
        for event, elem in iterator:
            if event == "end" and elem.tag == "object":
                name = elem.attrib.get( "name" )
                type = elem.attrib[ "type" ]
                position = (
                    float( elem.attrib[ "x" ] ),
                    float( elem.attrib[ "y" ] )
                )
                size = Size(
                    float( elem.attrib[ "width" ] ),
                    float( elem.attrib[ "height" ] )
                )
                return Object( name, type, position, size )
            else:
                raise unexpectedElem( event, elem )

    def parseTileAnimationFrame( frameElem, iterator ):
        for event, elem in iterator:
            if event == "end" and elem.tag == "frame":
                return
            else:
                raise unexpectedElem( event, elem )

    def parseTileAnimation( tileAnimationElem, iterator ):
        for event, elem in iterator:
            if event == "end" and elem.tag == "animation":
                return
            elif event == "start" and elem.tag == "frame":
                parseTileAnimationFrame( elem, iterator )
            else:
                raise unexpectedElem( event, elem )

    def parseTilesetImage( imageElem, iterator ):
        for event, elem in iterator:
            if event == "end" and elem.tag == "image":
                source = elem.attrib[ "source" ]
                size = Size(
                    int( elem.attrib[ "width" ] ),
                    int( elem.attrib[ "height" ] )
                )
                return TilesetImage( source, size )
            else:
                raise unexpectedElem( event, elem )

    def parseTilesetTile( tileElem, iterator ):
        properties = None
        image = None
        for event, elem in iterator:
            if event == "end" and elem.tag == "tile":
                # \todo Add animation
                id = int( elem.attrib[ "id" ] )
                return TilesetTile( id, properties, image )
            elif event == "start" and elem.tag == "properties":
                properties = parseProperties( elem, iterator )
            elif event == "start" and elem.tag == "animation":
                parseTileAnimation( elem, iterator )
            elif event == "start" and elem.tag == "image":
                # Per-tile image is used for "Collection of Images" type
                # tilesets.
                image = parseTilesetImage( elem, iterator )
            else:
                raise unexpectedElem( event, elem )

    def parseTileset( tilesetElem, iterator ):
        if "source" in tilesetElem.attrib:
            source = tilesetElem.attrib[ "source" ]
            sourceFullPath = os.path.join( os.path.dirname( infile ), source )
            extIterator = cElementTree.iterparse( sourceFullPath,
                                                  events=("start", "end") )
            tileset = None
            for event, elem in extIterator:
                if event == "start" and elem.tag == "tileset":
                    tileset = parseTileset( elem, extIterator )
                else:
                    raise unexpectedElem( event, elem )

            for event, elem in iterator:
                if event == "end" and elem.tag == "tileset":
                    # Monkeypatch the correct firstGid and baseDir into the
                    # tileset.
                    tileset.firstGid = int( elem.attrib[ "firstgid" ] )
                    tileset.baseDir = os.path.dirname( sourceFullPath )
                    return tileset
                else:
                    raise unexpectedElem( event, elem )
        else:
            tilesetImage = None
            tiles = {}
            for event, elem in iterator:
                if event == "end" and elem.tag == "tileset":
                    # Allow firstGid to be None because external tilesets
                    # don't have it.
                    firstGid = None
                    if "firstgid" in elem.attrib:
                        firstGid = int( elem.attrib[ "firstgid" ] )
                    tileSize = Size(
                        int( elem.attrib[ "tilewidth" ] ),
                        int( elem.attrib[ "tileheight" ] )
                    )
                    # For internal tilesets any paths within the tileset are
                    # relative to the directory of the map file.
                    baseDir = os.path.dirname( infile )
                    return Tileset( firstGid, tilesetImage, tileSize, tiles,
                                    baseDir )
                elif event == "start" and elem.tag == "image":
                    tilesetImage = parseTilesetImage( elem, iterator )
                elif event == "start" and elem.tag == "tile":
                    tilesetTile = parseTilesetTile( elem, iterator )
                    tiles[ tilesetTile.id ] = tilesetTile
                else:
                    raise unexpectedElem( event, elem )

    def parseMap( mapElem, iterator ):
        tilesets = []
        layers = []
        objectLayers = []
        for event, elem in iterator:
            if event == "end" and elem.tag == "map":
                size = Size(
                    int( elem.attrib[ "width" ] ),
                    int( elem.attrib[ "height" ] )
                )
                tileSize = Size(
                    int( elem.attrib[ "tilewidth" ] ),
                    int( elem.attrib[ "tileheight" ] )
                )
                return Map( size, tileSize, tilesets, layers, objectLayers )
            elif event == "start" and elem.tag == "tileset":
                tileset = parseTileset( elem, iterator )
                tilesets.append( tileset )
            elif event == "start" and elem.tag == "layer":
                layers.append( parseLayer( elem, iterator ) )
            elif event == "start" and elem.tag == "objectgroup":
                objectLayers.append( parseObjectLayer( elem, iterator ) )
            else:
                raise unexpectedElem( event, elem )

    # -------------------------------------------------------------------------

    iterator = cElementTree.iterparse( infile, events=("start", "end") )
    for event, elem in iterator:
        if event == "start" and elem.tag == "map":
            return parseMap( elem, iterator )
        else:
            raise unexpectedElem( event, elem )

def combineProperties( propertyList, palette ):
    # \note There can be several properties per tile, because they can come
    #       from different layers.

    # Solid will be true if at least one property specifies Solid=true.
    solid = False

    for properties in propertyList:
        if properties.getBool( "Solid" ):
            solid = True

    paletteString = "{:3}".format( palette )
    combinedProperties = [ paletteString ]
    if solid:
        combinedProperties.append( kSolidAttribute )

    return frozenset( combinedProperties )

def processFlattenedMap( flatMap, flatProperties, nginCommonMapData ):
    # \todo Ensure that the flattened map size is a multiple of screen size(?)

    flatMapWidthMt16  = flatMap.size[ 0 ] / kMt16SizeX
    flatMapHeightMt16 = flatMap.size[ 1 ] / kMt16SizeY

    def processTile8( tile8X, tile8Y ):
        # Extract the tile data from the map.
        cropBox = (
            tile8X,
            tile8Y,
            tile8X + kTile8SizeX,
            tile8Y + kTile8SizeY
        )
        tile = flatMap.crop( cropBox )
        rawTile = tile.tostring()
        # Generate the 2bpp tile by masking the upper bits.
        tile2bpp = "".join( map( lambda x: chr( ord( x ) & 0b11 ), rawTile ) )

        tilePalette = None
        for pixel in rawTile:
            color = ord( pixel ) & 0b11
            # If color index 0 is used, the palette doesn't matter because
            # the background color is shared for all palettes.
            if color == 0:
                continue
            palette = ( ord( pixel ) & 0b1100 ) >> 2
            if tilePalette is not None and tilePalette != palette:
                raise Exception( "more than one palette used in the 16x16px" + \
                    " tile at ({}, {})".format( tile8X/kMt16SizeX,
                                                tile8Y/kMt16SizeY ) )

            tilePalette = palette

        # \note tilePalette can still be None if only the background color was
        #       used. None is used to mark "don't care" here.

        return nginCommonMapData.addTile( tile2bpp ), tilePalette

    def processMt16( mt16X, mt16Y ):
        mt16 = []
        palette = None
        for tile8Y in xrange( mt16Y, mt16Y+kMt16SizeY, kTile8SizeY ):
            for tile8X in xrange( mt16X, mt16X+kMt16SizeX, kTile8SizeX ):
                tile8Index, tile8Palette = processTile8( tile8X, tile8Y )
                mt16.append( tile8Index )
                # \note tile8Palette could be None for "don't care"
                if palette is not None and tile8Palette is not None and \
                        palette != tile8Palette:
                    raise Exception( "more than one palette used in the 16x16px" + \
                        " tile at ({}, {})".format( mt16X/kMt16SizeX,
                                                    mt16Y/kMt16SizeY ) )
                if tile8Palette is not None:
                    palette = tile8Palette

        # If palette is "don't care", any palette will do, so choose 0.
        if palette is None:
            palette = 0

        # Fetch the properties for this metatile.
        propertyX = mt16X / kMt16SizeX
        propertyY = mt16Y / kMt16SizeY
        propertyList = flatProperties[ propertyY * flatMapWidthMt16 + propertyX ]

        # Combine the properties down to something that 1) can be compared
        # for uniqueness 2) is usable in the engine.
        combinedProperties = combineProperties( propertyList, palette )
        mt16.append( combinedProperties )

        mt16 = tuple( mt16 )
        return nginCommonMapData.addMt16( mt16 )

    def processMt32( mt32X, mt32Y ):
        mt32 = []
        for mt16Y in xrange( mt32Y, mt32Y+kMt32SizeY, kMt16SizeY ):
            for mt16X in xrange( mt32X, mt32X+kMt32SizeX, kMt16SizeX ):
                mt16Index = processMt16( mt16X, mt16Y )
                mt32.append( mt16Index )

        mt32 = tuple( mt32 )
        return nginCommonMapData.addMt32( mt32 )

    def processScreen( screenX, screenY ):
        screen = []
        for mt32Y in xrange( screenY, screenY+kScreenSizeY, kMt32SizeY ):
            for mt32X in xrange( screenX, screenX+kScreenSizeX, kMt32SizeX ):
                mt32Index = processMt32( mt32X, mt32Y )
                screen.append( mt32Index )

        screen = tuple( screen )
        return nginCommonMapData.addScreen( screen )

    def processMap():
        map = []
        for screenY in xrange( 0, flatMap.size[ 1 ], kScreenSizeY ):
            for screenX in xrange( 0, flatMap.size[ 0 ], kScreenSizeX ):
                screenIndex = processScreen( screenX, screenY )
                map.append( screenIndex )

        return nginCommonMapData.addMap( NginMapData( map ) )

    return processMap()

def processMap( map_, nginCommonMapData, produceDebugImage ):
    # \note Since tile sizes in tile sets may not be the same as the base
    #       tile size of the map, the render order of the map matters (tile on
    #       a layer can overlap tiles on the same layer).
    # \note The origin for tile drawing is the bottom left corner.

    # Attributes don't behave very well if the map tile size is not 16px,
    # even though it could be technically supported.
    assert map_.tileSize.width  == 16
    assert map_.tileSize.height == 16

    if produceDebugImage:
        debugImage = Image.new( "RGB", map_.pixelSize() )
    flatImage = Image.new( "P", map_.pixelSize() )
    # Flattened attributes. One list for each tile, containing references to
    # tile Properties.
    flatProperties = []
    for i in xrange( map_.size.width * map_.size.height ):
        flatProperties.append( [] )

    for layer in map_.layers:
        if layer.properties.getBool( "IgnoreGraphics" ) and \
           layer.properties.getBool( "IgnoreAttributes" ):
            continue

        for y in xrange( map_.size.height ):
            baseOffset = y * map_.size.width
            for x in xrange( map_.size.width ):
                offset = baseOffset + x
                gid = layer.data[ offset ]
                if gid == kEmptyGid:
                    continue

                tileset = map_.tilesetFromGid( gid )

                if not layer.properties.getBool( "IgnoreGraphics" ):
                    tile, tileTransparency = tileset.getTilePilImage( gid )

                    destX = x * map_.tileSize.width
                    # Adjust Y position because Tiled draws tiles at the
                    # bottom left corner of the tile.
                    destY = y * map_.tileSize.height - \
                        ( tile.size[ 1 ] - map_.tileSize.height )
                    flatImage.paste( tile, ( destX, destY ), tileTransparency )
                    if produceDebugImage:
                        debugImage.paste( tile, ( destX, destY ), tileTransparency )

                if not layer.properties.getBool( "IgnoreAttributes" ):
                    # \todo Apply attributes to the entire area covered by the
                    #       size of the tile in the tileset. Note that some
                    #       tiles may not cover full tiles, since Tiled allows
                    #       tileset tiles to have a size that is not multiple
                    #       of the map tile size.
                    tile = tileset.getTile( gid )
                    if tile is not None:
                        allProperties = flatProperties[ y * map_.size.width + x ]
                        if tile.properties is not None:
                            allProperties.append( tile.properties )

    # Go through the resulting flattened map.
    # Extract 8x8px tiles, 16x16px metatiles, 32x32px metatiles and screens.
    mapIndex = processFlattenedMap( flatImage, flatProperties, nginCommonMapData )
    mapData = nginCommonMapData.maps[ mapIndex ]

    if produceDebugImage:
        debugImage.save( "debug{}.png".format( mapIndex ) )

    # \todo Verify somewhere that map size is a multiple of screen size,
    #       or pad with empty space accordingly.
    kMt16PerScreenX, kMt16PerScreenY = 256/16, 256/16
    mapData.sizeScreens = (
        ( map_.size.width  + kMt16PerScreenX - 1 ) / kMt16PerScreenX,
        ( map_.size.height + kMt16PerScreenY - 1 ) / kMt16PerScreenY
    )

    # Gather objects/markers from the object layers.
    mapData.markers = []
    mapData.objects = []
    for objectLayer in map_.objectLayers:
        for object in objectLayer.objects:
            if object.type.lower() == "ngin_marker":
                # Round the position to an integer.
                mapData.markers.append( (
                    object.name,
                    ( int( round( object.position[0] ) ),
                      int( round( object.position[1] ) ) )
                ) )
            else:
                mapData.objects.append( object )

def listToString( list, width=3 ):
    return ", ".join( map( lambda x: "{:{width}}".format( x, width=width ), list ) )

def writeByteArray( f, indentText, list ):
    kBytesPerLine = 8
    f.write( indentText )
    numLines = ( len( list ) + kBytesPerLine-1 ) / kBytesPerLine
    for i in xrange( numLines ):
        start = i*kBytesPerLine
        end = start + kBytesPerLine
        sliced = list[ start:end ]
        if i != 0:
            f.write( " " * len( indentText ) )
        f.write( ".byte " + listToString( sliced ) + "\n" )

def writeNginData( nginCommonMapData, outPrefix, symbols ):
    with open( outPrefix + ".s", "w" ) as f:
        f.write( "; Data generated by Ngin tiled-map-importer.py\n\n" )

        outPrefixBase = os.path.basename( outPrefix )
        f.write( '.include "{}.inc"\n'.format( outPrefixBase ) )
        f.write( '.include "ngin/ngin.inc"\n\n' )

        # \todo Make it possible to specify the segment.
        f.write( '.segment "RODATA"\n\n' )

        f.write( ".scope screens\n" )
        for screenIndex, screen in enumerate( nginCommonMapData.uniqueScreens ):
            f.write( "    .proc screen{}\n".format( screenIndex ) )
            for y in xrange( 8 ):
                start = 8 * y
                end = start + 8
                writeByteArray( f, "        ", screen[ start:end ] )
            f.write( "    .endproc\n\n" )
        f.write( ".endscope\n\n" )

        kScreenPointersTemplate = """\
.scope screenPointers
    .define screenPointers_ {}
    lo: .lobytes screenPointers_
    hi: .hibytes screenPointers_
    .undefine screenPointers_
.endscope

"""
        f.write( kScreenPointersTemplate.format( listToString(
            map( lambda x: "screens::screen{}".format( x ),
                 range( len( nginCommonMapData.uniqueScreens ) ) )
        ) ) )

        f.write( ".scope _32x32Metatiles\n" )
        writeByteArray( f, "    topLeft:     ",
            map( lambda x: x[ 0 ], nginCommonMapData.uniqueMt32 ) )
        writeByteArray( f, "    topRight:    ",
            map( lambda x: x[ 1 ], nginCommonMapData.uniqueMt32 ) )
        writeByteArray( f, "    bottomLeft:  ",
            map( lambda x: x[ 2 ], nginCommonMapData.uniqueMt32 ) )
        writeByteArray( f, "    bottomRight: ",
            map( lambda x: x[ 3 ], nginCommonMapData.uniqueMt32 ) )
        f.write( ".endscope\n\n" )

        f.write( 'ngin_pushSeg "CHR_ROM"\n' )
        f.write( ".proc chrData\n" )
        f.write( '    .incbin "{}.chr"\n'.format( outPrefixBase ) )
        f.write( ".endproc\n" )
        f.write( "ngin_popSeg\n\n" )

        def withBase( index ):
            return lambda x: "B+{}".format( x[ index ] )

        f.write( ".scope _16x16Metatiles\n" )
        f.write( "    B = .lobyte( chrData/ppu::kBytesPer8x8Tile )\n" )
        writeByteArray( f, "    topLeft:     ",
            map( withBase( 0 ), nginCommonMapData.uniqueMt16 ) )
        writeByteArray( f, "    topRight:    ",
            map( withBase( 1 ), nginCommonMapData.uniqueMt16 ) )
        writeByteArray( f, "    bottomLeft:  ",
            map( withBase( 2 ), nginCommonMapData.uniqueMt16 ) )
        writeByteArray( f, "    bottomRight: ",
            map( withBase( 3 ), nginCommonMapData.uniqueMt16 ) )
        writeByteArray( f, "    attributes0: ",
            map( lambda x: "|".join( x[ 4 ] ), nginCommonMapData.uniqueMt16 ) )
        f.write( ".endscope\n\n" )

        # ---------------------------------------------------------------------

        for mapIndex, nginMapData in enumerate( nginCommonMapData.maps ):
            f.write( ".scope map{}\n".format( mapIndex ) )

            # \todo Add some comment lines to results indicating from what
            #       files the results were generated.

            def writeRow( y, symbolY ):
                baseOffset = y * nginMapData.sizeScreens[ 0 ]
                start = baseOffset
                end = start + nginMapData.sizeScreens[ 0 ]
                slice = nginMapData.map[ start:end ]
                # Duplicate the last element to add a sentinel value at the
                # right side to simplify engine code.
                slice.append( slice[ -1] )
                f.write( "        row{}: .byte {}\n".format(
                    symbolY, listToString( slice )
                ) )

            # Screen rows
            f.write( "    .scope screenRows\n" )
            for y in xrange( nginMapData.sizeScreens[ 1 ] ):
                writeRow( y, y )
            # Add a sentinel row.
            writeRow( nginMapData.sizeScreens[ 1 ]-1,
                      nginMapData.sizeScreens[ 1 ] )
            f.write( "    .endscope\n\n" )

            # Screen row pointers
            kScreenRowPointersTemplate = """\
    .scope screenRowPointers
        .define screenRowPointers_ {}
        lo: .lobytes screenRowPointers_
        hi: .hibytes screenRowPointers_
        .undefine screenRowPointers_
    .endscope

"""
            f.write( kScreenRowPointersTemplate.format( listToString(
                map( lambda x: "screenRows::row{}".format( x ),
                     # 1 is added because of the sentinel row.
                     range( nginMapData.sizeScreens[ 1 ]+1 ) )
            ) ) )

            # Objects
            kObjectsTemplate = """\
    .scope objects
        ; Object names: {}
        .define objectX {}
        .define objectY {}
        {}
        xLo:     .lobytes objectX
        xHi:     .hibytes objectX
        yLo:     .lobytes objectY
        yHi:     .hibytes objectY
        type:    .byte    {}
        ySorted: .byte    {}
        .undefine objectX
        .undefine objectY
    .endscope

"""
            objects = nginMapData.objects

            # \todo Should we handle object size here?

            # Add a sentinel object at the top-left and bottom-right corners.
            # Both positions are outside the map boundaries.
            #       (Use (0,0) for top-left, and $FFFF, $FFFF for bottom right)
            objects.append( Object(
                "sentinelTopLeft", "ngin_Object_kInvalidTypeId",
                nginMapData.nginWorldPointToMapPixel( ( 0, 0 ) ), size=None
            ) )
            objects.append( Object(
                "sentinelBottomRight", "ngin_Object_kInvalidTypeId",
                nginMapData.nginWorldPointToMapPixel( ( 0xFFFF, 0xFFFF ) ), size=None
            ) )

            # Sort the object list based on the X coordinate.
            objects.sort( key=lambda object: object.position[0] )

            # Create a list of indices into the X list, then sort that based on the
            # Y coordinate.
            ySortedObjects = list( enumerate( objects ) )
            ySortedObjects.sort( key=lambda x: x[1].position[1] )

            objectTypes = map( lambda x: x.type, objects )
            # Get the unique object types for import.
            uniqueObjectTypes = set( objectTypes )
            uniqueObjectTypes.remove( "ngin_Object_kInvalidTypeId" )

            objectNginWorldPoints = map(
                lambda x: nginMapData.mapPixelToNginWorldPoint( x.position ),
                objects
            )
            importZp = ".importzp "
            if len( uniqueObjectTypes ) == 0:
                importZp = "; No imports"
            f.write( kObjectsTemplate.format(
                listToString( map( lambda x: x.name, objects ), width=1 ),
                listToString( map( lambda x: int( round( x[0] ) ),
                                   objectNginWorldPoints ) ),
                listToString( map( lambda x: int( round( x[1] ) ),
                                   objectNginWorldPoints ) ),
                importZp + listToString( uniqueObjectTypes ),
                listToString( objectTypes ),
                listToString( map( lambda x: x[0], ySortedObjects ) ),
            ) )

            # Calculate the map boundaries.
            boundaryLeftTop = nginMapData.mapPixelToNginWorldPoint( ( 0, 0 ) )
            boundaryRightBottom = nginMapData.mapPixelToNginWorldPoint( (
                nginMapData.sizeScreens[ 0 ] * kScreenSizeX,
                nginMapData.sizeScreens[ 1 ] * kScreenSizeY,
            ) )

            # Map header
            # \todo Should probably add a level of indirection for the metatile
            #       set.
            kHeaderTemplate = """\
    ; ngin_MapData_Header
    .proc header
        ; widthScreens
        .byte {}
        ; heightScreens
        .byte {}
        ; boundaryLeft
        .word ${:04X}
        ; boundaryRight
        ; \\todo Use view width from configuration
        .word ${:04X} - (256-16) - 1 ; Inclusive
        ; boundaryTop
        .word ${:04X}
        ; boundaryBottom
        ; \\todo Use view height from configuration
        .word ${:04X} - (240-16) - 1 ; Inclusive
        ; numObjects
        .byte {}
        ; ngin_MapData_Pointers
        .addr screenRowPointers::lo
        .addr screenRowPointers::hi
        .addr screenPointers::lo
        .addr screenPointers::hi
        .addr _16x16Metatiles::topLeft
        .addr _16x16Metatiles::topRight
        .addr _16x16Metatiles::bottomLeft
        .addr _16x16Metatiles::bottomRight
        .addr _16x16Metatiles::attributes0
        .addr _32x32Metatiles::topLeft
        .addr _32x32Metatiles::topRight
        .addr _32x32Metatiles::bottomLeft
        .addr _32x32Metatiles::bottomRight
        .addr objects::xLo
        .addr objects::xHi
        .addr objects::yLo
        .addr objects::yHi
        .addr objects::type
        .addr objects::ySorted
    .endproc
"""
            f.write( kHeaderTemplate.format(
                nginMapData.sizeScreens[ 0 ],
                nginMapData.sizeScreens[ 1 ],
                boundaryLeftTop[0], boundaryRightBottom[0],
                boundaryLeftTop[1], boundaryRightBottom[1],
                len( objects )
            ) )

            f.write( ".endscope\n\n" )

            f.write( "{} = map{}::header\n\n".format( symbols[ mapIndex ],
                                                      mapIndex ) )

    with open( outPrefix + ".chr", "wb" ) as f:
        for tile in nginCommonMapData.uniqueTiles:
            packed = common.packNesTile( tile )
            f.write( packed )

    with open( outPrefix + ".inc", "w" ) as f:
        uniqueSymbol = "NGIN_TILED_MAP_IMPORTER_" + \
                       str( uuid.uuid4() ).upper().replace( "-", "_" )
        f.write( ".if .not .defined( {} )\n".format( uniqueSymbol ) )
        f.write( "{} = 1\n\n".format( uniqueSymbol ) )
        f.write( '.include "ngin/ngin.inc"\n\n' )

        def writeMarker( name, position ):
            worldPoint = nginMapData.mapPixelToNginWorldPoint( position )
            f.write( "        {} = ngin_immVector2_16 {}, {}\n".format(
                name, worldPoint[0], worldPoint[1] ) )

        for symbol, nginMapData in zip( symbols, nginCommonMapData.maps ):
            f.write( ".global {}\n".format( symbol ) )
            f.write( ".scope {}\n".format( symbol ) )

            f.write( "    .scope markers\n" )
            writeMarker( "topLeft", ( 0, 0 ) )
            for marker in nginMapData.markers:
                assert marker[0] != "topLeft"
                writeMarker( marker[0], marker[1] )
            f.write( "    .endscope\n" )

            f.write( ".endscope\n" )
        f.write( "\n.endif\n" )

def main():
    argParser = argparse.ArgumentParser(
        description="Import Tiled maps into Ngin" )
    argParser.add_argument( "-i", "--infile", nargs="+", required=True )
    argParser.add_argument( "-s", "--symbol", nargs="+", required=True )
    argParser.add_argument( "-o", "--outprefix", required=True,
        help="prefix for output files" )
    argParser.add_argument( "--debugimage", action="store_true",
        default=False, help="produce an image of the flattened map" )

    args = argParser.parse_args()

    if args.symbol is not None and len( args.infile ) != len( args.symbol ):
        argParser.error( "number of infiles must match the number of symbols" )

    nginCommonMapData = NginCommonMapData()
    for infile in args.infile:
        map = parseTmx( infile )
        mapIndex = processMap( map, nginCommonMapData, args.debugimage )

    print "Number of screens: {}".format( len( nginCommonMapData.uniqueScreens ) )
    print "Number of 32x32px MT: {}".format( len( nginCommonMapData.uniqueMt32 ) )
    print "Number of 16x16px MT: {}".format( len( nginCommonMapData.uniqueMt16 ) )
    print "Number of 8x8 tiles: {}".format( len( nginCommonMapData.uniqueTiles ) )
    print "Number of maps: {}".format( len( nginCommonMapData.maps ) )

    # \todo Check whether the resulting MT amounts etc are within set limits.
    #       Also check object amounts for each map.

    writeNginData( nginCommonMapData, args.outprefix, args.symbol )

main()
