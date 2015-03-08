.include "ngin/build-log.inc"

.export __ngin_BuildLog_forceImport : absolute = 1

.segment "NGIN_BUILD_LOG_HEADER"
    ngin_BuildLog_string "Ngin Build Log"
    ngin_BuildLog_newLine
    ngin_BuildLog_string "--------------"
    ngin_BuildLog_newLine
    ngin_BuildLog_newLine

.segment "NGIN_BUILD_LOG"
    ngin_BuildLog_string "NGIN_CODE segment size:"
    ngin_BuildLog_newLine
    .import __NGIN_CODE_SIZE__
    ngin_BuildLog_decimalInteger __NGIN_CODE_SIZE__
    ngin_BuildLog_string " bytes"
    ngin_BuildLog_newLine

    ngin_BuildLog_string "CODE segment size:"
    ngin_BuildLog_newLine
    .import __CODE_SIZE__
    ngin_BuildLog_decimalInteger __CODE_SIZE__
    ngin_BuildLog_string " bytes"
    ngin_BuildLog_newLine
