.if .not .defined( NGIN_MEMORY_INC_INCLUDED )
NGIN_MEMORY_INC_INCLUDED = 1

; Variables shared by all memory copy routines.
.globalzp __ngin_genericCopy_destination
.globalzp __ngin_genericCopy_source
.global   __ngin_genericCopy_size

.macro __ngin_setupGenericCopyParameters destination, source, size
    __ngin_requireParameter {destination}, "destination"
    __ngin_requireParameter {source}, "source"
    __ngin_requireParameter {size}, "size"

    ngin_mov16 __ngin_genericCopy_destination, {destination}
    ngin_mov16 __ngin_genericCopy_source, {source}
    ngin_mov16 __ngin_genericCopy_size, {size}
.endmacro

.global __ngin_copyMemory
.macro ngin_copyMemory destination, source, size
    __ngin_setupGenericCopyParameters {destination}, {source}, {size}
    jsr __ngin_copyMemory
.endmacro

.global __ngin_copyPort
.macro ngin_copyPort destination, source, size
    __ngin_setupGenericCopyParameters {destination}, {source}, {size}
    jsr __ngin_copyPort
.endmacro

.global __ngin_copyMemoryToPort
.macro ngin_copyMemoryToPort destination, source, size
    __ngin_setupGenericCopyParameters {destination}, {source}, {size}
    jsr __ngin_copyMemoryToPort
.endmacro

.global __ngin_copyPortToMemory
.macro ngin_copyPortToMemory destination, source, size
    __ngin_setupGenericCopyParameters {destination}, {source}, {size}
    jsr __ngin_copyPortToMemory
.endmacro

.global __ngin_fillMemory
.macro ngin_fillMemory destination, source, size
    __ngin_setupGenericCopyParameters {destination}, {source}, {size}
    jsr __ngin_fillMemory
.endmacro

.global __ngin_fillPort
.macro ngin_fillPort destination, source, size
    __ngin_setupGenericCopyParameters {destination}, {source}, {size}
    jsr __ngin_fillPort
.endmacro

.endif
