.include "ngin/build-log.inc"

.export __ngin_BuildLog_forceImport : absolute = 1

.macro printSegmentSize segment, segmentType
    ; Make sure the segment exists.
    .if .blank( {segmentType} )
        ngin_pushSeg segment
    .else
        ngin_pushSeg segment : segmentType
    .endif
    ngin_popSeg
    .define __sizeIdentifier .ident( .sprintf( "__%s_SIZE__", segment ) )
    .import __sizeIdentifier
    __ngin_BuildLog_string .sprintf( "  %25s", segment )
    __ngin_decimalInteger __sizeIdentifier
    __ngin_BuildLog_string " bytes"
    __ngin_BuildLog_newLine
    .undefine __sizeIdentifier
.endmacro

.segment "NGIN_BUILD_LOG_HEADER"
    __ngin_BuildLog_string "Ngin Build Log"
    __ngin_BuildLog_newLine
    __ngin_BuildLog_string "--------------"
    __ngin_BuildLog_newLine
    __ngin_BuildLog_newLine

.segment "NGIN_BUILD_LOG"
    __ngin_BuildLog_string "Ngin Segments:"
    __ngin_BuildLog_newLine
    printSegmentSize "NGIN_CODE"
    printSegmentSize "NGIN_RESET_PROLOGUE"
    printSegmentSize "NGIN_RESET_CONSTRUCTORS"
    printSegmentSize "NGIN_RESET_EPILOGUE"
    printSegmentSize "NGIN_MUSE_CODE"
    printSegmentSize "NGIN_RODATA"
    printSegmentSize "NGIN_BSS"
    printSegmentSize "NGIN_ZEROPAGE", zeropage
    __ngin_BuildLog_newLine

    __ngin_BuildLog_string "User Segments:"
    __ngin_BuildLog_newLine
    printSegmentSize "CODE"
    printSegmentSize "RODATA"
    printSegmentSize "BSS"
    __ngin_BuildLog_newLine
