# This tool imports NES palettes from image file(s).
# The palette is imported by matching the RGB colors from the paletted input
# image to the NES global palette. The actual image contents don't matter.

# NOTE: Requires Pillow: https://python-pillow.github.io/

import argparse
from PIL import Image
import uuid
import os
import sys
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)),
                             "..", "common"))
from nes_palette import kNtscNesPalette
import common

class SymbolArg( object ):
    def __init__( self, symbol ):
        self.symbol = symbol

class InfileArg( object ):
    def __init__( self, infile ):
        self.infile = infile

class Infile( object ):
    def __init__( self, file, symbol ):
        self.file       = file
        self.symbol     = symbol

def findClosestMatch( rgb ):
    # Find the "best" candidates by sorting based on the Euclidean distance.
    best = sorted(
        enumerate( kNtscNesPalette[ 0:64 ] ),
        key=lambda x: sum( [ (a-b)**2 for a,b in zip( x[1], rgb ) ] )
    )
    bestIndex = best[ 0 ][ 0 ]
    if bestIndex == 0xD: bestIndex = 0xF # Avoid invalid black.
    return bestIndex

def importPalette( infile ):
    pilImage = Image.open( infile.file )
    # Image must be paletted.
    assert pilImage.mode == "P"
    # Must be an RGB palette.
    assert pilImage.palette.mode == "RGB"
    palette = pilImage.palette.palette

    nesPalette = []
    for i in xrange( 0, len( palette ), 3 ):
        rgb = map( ord, palette[ i:i+3 ] )
        nesIndex = findClosestMatch( rgb )
        nesPalette.append( nesIndex )

    return ( infile.symbol, nesPalette )

def writeData( outPrefix, allData ):
    with open( outPrefix + ".s", "w" ) as f:
        f.write( "; Data generated by Ngin palette-importer.py\n\n" )

        outPrefixBase = os.path.basename( outPrefix )
        f.write( '.include "{}.inc"\n'.format( outPrefixBase ) )
        f.write( '.include "ngin/ngin.inc"\n\n' )

        f.write( 'ngin_pushSeg "RODATA"\n\n' )

        for symbol, data in allData:
            f.write( ".proc {}\n".format( symbol ) )
            common.writeByteArray( f, " "*4, data, bytesPerLine=4 )
            f.write( ".endproc\n\n" )

        f.write( "ngin_popSeg\n\n" )

    with open( outPrefix + ".inc", "w" ) as f:
        uniqueSymbol = "NGIN_PALETTE_IMPORTER_" + \
                       str( uuid.uuid4() ).upper().replace( "-", "_" )
        f.write( ".if .not .defined( {} )\n".format( uniqueSymbol ) )
        f.write( "{} = 1\n\n".format( uniqueSymbol ) )
        f.write( '.include "ngin/ngin.inc"\n\n' )

        for symbol, data in allData:
            f.write( ".global {}\n".format( symbol ) )
            f.write( "{}_size = {}\n".format( symbol, len( data ) ) )

        f.write( "\n.endif\n" )

def main():
    argParser = argparse.ArgumentParser(
        description="Import NES palette(s) from image(s)" )

    argParser.add_argument( "-i", "--infile", dest="infiles", action="append",
                            type=InfileArg, metavar="FILE", required=True )
    argParser.add_argument( "-s", "--symbol", dest="infiles", action="append",
                            type=SymbolArg, metavar="SYMBOL", required=True )

    argParser.add_argument( "-o", "--outprefix", required=True,
        help="prefix for output files", metavar="PREFIX" )

    args = argParser.parse_args()

    # Gather the input files and their options from the command arguments.
    gatheredInfiles = []
    currentSymbol   = None
    for entry in args.infiles:
        if isinstance( entry, SymbolArg ):
            currentSymbol = entry.symbol
        elif isinstance( entry, InfileArg ):
            assert currentSymbol != None
            gatheredInfiles.append( Infile(
                entry.infile, currentSymbol
            ) )
            currentSymbol = None

    results = []
    for infile in gatheredInfiles:
        results.append( importPalette( infile ) )

    writeData( args.outprefix, results )

main()