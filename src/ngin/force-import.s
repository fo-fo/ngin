; The sole purpose of this file is to export a symbol that will be force
; imported from the command line. Then, the .forceimport commands in this file
; will in turn force import other mandatory parts of the engine.

.export __ngin_forceImport : absolute = 1

.forceimport __ngin_inesHeaderForceImport
.forceimport __ngin_vectorsForceImport
.forceimport __ngin_BuildLog_forceImport
.forceimport __ngin_forceSegmentForceImport
.forceimport __ngin_logForceImport
