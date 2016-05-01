# This tool generates cc65 linker configuration files for Ngin based on
# given parameters. The primary purpose is (1) to share common parts of the
# configuration between targets, and (2) to configure parameters for which
# the default cc65 linker configuration format is too inflexible (e.g. CHR
# and PRG size).

import argparse

kMapperIds = [ "nrom", "fme-7" ]

kConfigPart1 = """\
symbols
{{
    # How big of a stack is used for function stack frames. The rest of the
    # stack can be used for other purposes.
    __ngin_stackSize: type = weak, value = 16;

    __ngin_prgSize: type = export, value = {prgSize};
    __ngin_chrSize: type = export, value = {chrSize};

    __ngin_defaultIrq: type = import;
    __ngin_irq: type = weak, value = __ngin_defaultIrq;
}}

memory
{{
    INES_HEADER:
        start   = 0,
        size    = 16,
        type    = ro,
        fillval = 0,
        fill    = yes;

    ZEROPAGE:
        start = 0,
        size  = 256,
        type  = rw;

    # The area of stack memory that can be used for user-defined purposes.
    STACK:
        start = $100,
        size  = 256 - __ngin_stackSize,
        type  = rw;

    RAM:
        # Skip zeropage and stack.
        start = $200,
        size  = 2*1024 - 2*256,
        type  = rw;

"""

kConfigRom = """\
    {name}:
        start  = {start},
        size   = {sizeKb}*1024,
        type   = ro,
        fill   = yes,
        define = yes,
        file   = {file},
        {other};

"""

kConfigPart3 = """\
    BUILD_LOG:
        start = 0,
        size  = 64*1024,
        type  = ro,
        file  = "%O-build-log.txt";

    NDXDEBUG:
        start = 0,
        # 256 MB should be enough for everybody.
        size  = 256*1024*1024,
        type  = ro,
        file  = "%O.ndx";
}

segments
{
    INES_HEADER:
        load = INES_HEADER,
        type = ro;

    # MUSE needs the code to be aligned to a 256 byte page.
    # We don't do an explicit align here, but the order of segments ensures
    # it (and it's asserted in the source file).
    NGIN_MUSE_CODE:
        load     = PRG_ROM,
        type     = ro,
        define   = yes;

    NGIN_CODE:
        load   = PRG_ROM,
        type   = ro,
        define = yes,
        # The way alignment is handled in cc65 is sort of dumb at the moment.
        align  = 32;

    # This segment should be placed right before the entry point of the reset
    # code. It should never generate any actual data, only symbols in the debug
    # information.
    NGIN_LUA_REQUIRE:
        load     = PRG_ROM,
        type     = ro,
        optional = yes;

    NGIN_RESET_PROLOGUE:
        load   = PRG_ROM,
        type   = ro,
        define = yes;

    NGIN_MAPPER_INIT:
        load   = PRG_ROM,
        type   = ro,
        define = yes;

    NGIN_RESET_CONSTRUCTORS:
        load   = PRG_ROM,
        type   = ro,
        define = yes;

    NGIN_RESET_EPILOGUE:
        load   = PRG_ROM,
        type   = ro,
        define = yes;

    # \\todo Probably none of these segments should be optional so that
    #        their sizes could be shown in build log. Can be forced to exist
    #        by having an empty .segment block.
    NGIN_RODATA:
        load     = PRG_ROM,
        type     = ro,
        optional = yes,
        define   = yes;

    NGIN_ZEROPAGE:
        load     = ZEROPAGE,
        type     = zp,
        optional = yes,
        define   = yes;

    NGIN_STACK:
        load     = STACK,
        type     = bss,
        optional = yes;

    NGIN_SHADOW_OAM:
        load     = RAM,
        type     = bss,
        optional = yes;

    NGIN_BSS:
        load     = RAM,
        type     = bss,
        optional = yes,
        define   = yes;

    NGIN_BUILD_LOG_HEADER:
        load     = BUILD_LOG,
        type     = ro,
        optional = yes;

    NGIN_BUILD_LOG:
        load     = BUILD_LOG,
        type     = ro,
        optional = yes;

"""

kConfigSegment = """\
    {name}:
        load     = {romName},
        type     = ro,
        define   = yes,
        optional = {optional},
        {other};

"""

kConfigSegmentLoadRun = """\
    {name}:
        load     = {load},
        run      = {run},
        type     = ro,
        define   = yes,
        optional = {optional},
        {other};

"""

kConfigPart5 = """\
    OBJECT_CONSTRUCT_LO:
        load   = PRG_ROM,
        type   = ro,
        define = yes;

    OBJECT_CONSTRUCT_HI:
        load   = PRG_ROM,
        type   = ro,
        define = yes;

    OBJECT_UPDATE_LO:
        load   = PRG_ROM,
        type   = ro,
        define = yes;

    OBJECT_UPDATE_HI:
        load   = PRG_ROM,
        type   = ro,
        define = yes;

    ZEROPAGE:
        load     = ZEROPAGE,
        type     = zp,
        optional = yes;

    STACK:
        load     = STACK,
        type     = bss,
        optional = yes;

    BSS:
        load     = RAM,
        type     = bss,
        optional = yes,
        define   = yes;

    # \\todo DPCM sample start address should be the lowest possible address
    #       greater than $C000. Not possible to specify as such for NROM,
    #       but probably not a problem for mappers. Currently DPCM size is
    #       limited to roughly 1 KB. The address has to be 64 byte aligned.
    DPCM:
        load     = PRG_ROM,
        type     = ro,
        optional = yes,
        start    = $10000 - 1024;

    VECTORS:
        load  = PRG_ROM,
        type  = ro,
        start = $10000 - 6;

"""

kConfigPart6 = """\
    BUILD_LOG:
        load     = BUILD_LOG,
        type     = ro,
        optional = yes;

    NDXDEBUG:
        load     = NDXDEBUG,
        type     = ro,
        optional = yes;
}
"""

def isPowerOf2( number ):
    return number != 0 and ( number & ( number-1 ) ) == 0

def writeConfig( mapper, prgSize, chrSize, outPrefix ):
    if mapper == "nrom": # \todo Allow CHR-RAM?
        assert prgSize in ( 16, 32 ) and chrSize in ( 8, )

    # \note iNES format places additional restrictions, which are not
    #       checked here.
    assert isPowerOf2( prgSize ), "PRG size must be a power of two"
    assert isPowerOf2( chrSize ), "CHR size must be a power of two"

    dynamicBankSize = None
    numDynamicBanks = None
    staticBankSize  = None
    chrBankSize     = None
    numChrBanks     = None
    numRunSlots     = None # Number of slots to which data can be mapped.
    runSlotsBase    = None
    numChrRunSlots  = None
    chrRunSlotsBase = None

    if mapper == "nrom":
        numDynamicBanks = 0
        staticBankSize  = prgSize
    elif mapper == "fme-7":
        dynamicBankSize = 8 # KB
        numDynamicBanks = prgSize // dynamicBankSize - 1
        staticBankSize  = 8 # KB
        chrBankSize     = 1 # KB
        numChrBanks     = chrSize // chrBankSize
        numRunSlots     = 4 # $6000..DFFF, $2000 bytes each
        runSlotsBase    = 0x6000
        numChrRunSlots  = 8
        chrRunSlotsBase = 0x0000
    else:
        assert False, "unrecognized mapper"

    with open( outPrefix, "w" ) as f:
        f.write( "# Configuration generated by Ngin linker-configurer.py\n" )
        f.write( "# Mapper:          {}\n".format( mapper ) )
        f.write( "# PRG size:        {} KB\n".format( prgSize ) )
        f.write( "# CHR size:        {} KB\n".format( chrSize ) )
        f.write( "# numDynamicBanks: {}\n".format( numDynamicBanks ) )
        f.write( "# staticBankSize:  {} KB\n".format( staticBankSize ) )
        f.write( "\n" )

        f.write( kConfigPart1.format( prgSize=prgSize, chrSize=chrSize ) )

        # Create memory areas for dynamic banks.
        for i in range( numDynamicBanks ):
            f.write( kConfigRom.format( name="PRG_ROM_{}".format( i ),
                start=0,
                sizeKb=dynamicBankSize,
                file="%O",
                other="bank={}".format( i )
            ) )

            for j in range( numRunSlots ):
                start = runSlotsBase + j*dynamicBankSize*1024
                startStr = "${:X}".format( start )
                if j != 0:
                    prevStart = runSlotsBase + (j-1)*dynamicBankSize*1024
                    startStr += "+(__PRG_ROM_{}_{:04X}_LAST__-${:04X})".format(
                        i, prevStart, prevStart )
                f.write( kConfigRom.format( name="PRG_ROM_{}_{:04X}".format( i, start ),
                    start=startStr,
                    sizeKb=dynamicBankSize,
                    file='""',
                    other="bank={}".format( i )
                ) )

        f.write( kConfigRom.format( name="PRG_ROM",
            start="${:X}".format( 0x10000 - ( staticBankSize*1024 ) ),
            sizeKb=staticBankSize, file="%O",
            other="bank={}".format( numDynamicBanks )
        ) )

        if mapper == "nrom":
            f.write( kConfigRom.format( name="CHR_ROM", start=0,
                sizeKb=chrSize, file="%O", other="" ) )
        elif mapper == "fme-7":
            for i in range( numChrBanks ):
                name = "CHR_ROM_{}".format( i )
                f.write( kConfigRom.format( name=name, start=0,
                    sizeKb=chrBankSize, file="%O", other="bank={}".format( i ) ) )

                for j in range( numChrRunSlots ):
                    start = chrRunSlotsBase + j*chrBankSize*1024
                    startStr = "${:X}".format( start )
                    if j != 0:
                        prevStart = chrRunSlotsBase + (j-1)*chrBankSize*1024
                        startStr += "+(__CHR_ROM_{}_{:04X}_LAST__-${:04X})".format(
                            i, prevStart, prevStart )
                    f.write( kConfigRom.format( name="CHR_ROM_{}_{:04X}".format( i, start ),
                        start=startStr,
                        sizeKb=chrBankSize,
                        file='""',
                        other="bank={}".format( i )
                    ) )
        else:
            assert False

        f.write( kConfigPart3 )

        # Create segments for dynamic banks.
        for i in range( numDynamicBanks ):
            for j in range( numRunSlots ):
                start = runSlotsBase + j*dynamicBankSize*1024
                name = "CODE_{}_{:04X}".format( i, start )
                load = "PRG_ROM_{}".format( i )
                run = load + "_{:04X}".format( start )
                # \todo Maybe the CODE segment should have align since we KNOW
                #       (usually) that it can be aligned without waste.
                f.write( kConfigSegmentLoadRun.format( name=name,
                    load=load, run=run, optional="yes", other="" ) )

                name = "RODATA_{}_{:04X}".format( i, start )
                f.write( kConfigSegmentLoadRun.format( name=name,
                    load=load, run=run, optional="yes", other="" ) )

        f.write( kConfigSegment.format( name="CODE", romName="PRG_ROM",
            optional="no", other="align=32" ) )
        f.write( kConfigSegment.format( name="RODATA", romName="PRG_ROM",
            optional="yes", other="" ) )

        f.write( kConfigPart5 )

        # Create segments for CHR.
        if mapper == "nrom":
            f.write( kConfigSegment.format( name="GRAPHICS", romName="CHR_ROM",
                optional="yes", other="align=32" ) )
        elif mapper == "fme-7":
            for i in range( numChrBanks ):
                for j in range( numChrRunSlots ):
                    start = chrRunSlotsBase + j*chrBankSize*1024
                    name = "GRAPHICS_{}_{:04X}".format( i, start )
                    load = "CHR_ROM_{}".format( i )
                    run = load + "_{:04X}".format( start )
                    f.write( kConfigSegmentLoadRun.format( name=name,
                        load=load, run=run, optional="yes", other="align=32" ) )
        else:
            assert False

        f.write( kConfigPart6 )

def main():
    argParser = argparse.ArgumentParser(
        description="Generate Ngin linker configurations" )

    argParser.add_argument( "-m", "--mapper", required=True,
        help="mapper ID", choices=kMapperIds )
    argParser.add_argument( "-p", "--prgsize", required=True,
        help="PRG-ROM size", type=int )
    argParser.add_argument( "-c", "--chrsize", required=True,
        help="CHR-ROM size", type=int )
    argParser.add_argument( "-o", "--outprefix", required=True,
        help="prefix for output files", metavar="PREFIX" )

    args = argParser.parse_args()

    writeConfig( args.mapper, args.prgsize, args.chrsize, args.outprefix )

main()
