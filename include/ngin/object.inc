.if .not .defined( NGIN_OBJECT_INC_INCLUDED )
NGIN_OBJECT_INC_INCLUDED = 1

.include "ngin/core.inc"

; Terminology:
;   Object type:    type of an object, e.g. "ball"
;   Object:         a runtime instance of a specific object type

; Maximum supported object types is 255 to reserve one value for invalid.
ngin_Object_kMaxObjectTypes                 = 255

; Maximum number of custom parameter bytes that can be passed to object
; constructors
; \todo Probably should be configurable elsewhere (CMake? And provide defaults)
ngin_Object_kMaxCustomConstructorParameters = 2

; Maximum number of active objects at any given time
; \todo Should be configurable.
ngin_Object_kMaxActiveObjects               = 8

; Maximum data size that is allocated for each object
; \todo Should be configurable.
ngin_Object_kMaxObjectDataSize              = 13

; How many bytes need to be advanced to get to the next byte of an object
ngin_Object_kDataStride                     = ngin_Object_kMaxActiveObjects

; An invalid/unused object type ID
; \todo 0 might make a better invalid ID
ngin_Object_kInvalidTypeId                  = ngin_Object_kMaxObjectTypes

; An invalid object instance ID
ngin_Object_kInvalidId                      = 255

.struct ngin_Object_ConstructorParameters
    position    .tag ngin_Vector2_16
    custom      .res ::ngin_Object_kMaxCustomConstructorParameters
.endstruct

.global __ngin_Object_constructorParameters
.define ngin_Object_constructorParameter( param ) ~~( \
        __ngin_Object_constructorParameters + \
        ngin_Object_ConstructorParameters::param \
    )

.define __ngin_Object_declare_structIdentifier( identifier ) \
    .ident( .sprintf( "__ngin_Object__%s", .string( identifier ) ) )

.macro ngin_Object_declare identifier
    ; Use .globalzp because the maximum number of object types is 256.
    .globalzp identifier

    ; Save the identifier so that it can be used to verify the object data
    ; size at the end.
    .define __ngin_Object_declare_identifier identifier
    .struct __ngin_Object_declare_structIdentifier identifier
.endmacro

.macro ngin_Object_endDeclare
    .endstruct

    ; Verify that the object data size is not over the maximum.
    .local structSize
    structSize = .sizeof( __ngin_Object_declare_structIdentifier \
                          {__ngin_Object_declare_identifier} )
    .assert structSize <= ngin_Object_kMaxObjectDataSize, error, \
            .sprintf( "can't have more than %d object data bytes (had: %d)", \
                      ngin_Object_kMaxObjectDataSize, structSize )

    .undefine __ngin_Object_declare_identifier
.endmacro

.global __OBJECT_UPDATE_LO_RUN__
.global __OBJECT_UPDATE_HI_RUN__
.global __OBJECT_CONSTRUCT_LO_RUN__
.global __OBJECT_CONSTRUCT_HI_RUN__
.macro ngin_Object_define identifier
    .define __ngin_Object_define_identifier identifier

    .scope identifier

    ; Object handlers are called with RTS, so the addresses need to be adjusted.
    ; The update routine is called via a trampoline because it's split into
    ; two parts: rendering and the actual update.
    .local onUpdateRtsAdjusted
    onUpdateRtsAdjusted = __ngin_update-1
    .local onConstructRtsAdjusted
    onConstructRtsAdjusted = onConstruct-1

    ; Add the addresses to the correct segments. The object type ID is
    ; determined based on the address in the segment.

    ngin_pushSeg "OBJECT_UPDATE_LO"
    .local updateLo
    updateLo: .byte .lobyte( onUpdateRtsAdjusted )
    ngin_popSeg

    ngin_pushSeg "OBJECT_UPDATE_HI"
    .local updateHi
    updateHi: .byte .hibyte( onUpdateRtsAdjusted )
    ngin_popSeg

    ngin_pushSeg "OBJECT_CONSTRUCT_LO"
    .local constructLo
    constructLo: .byte .lobyte( onConstructRtsAdjusted )
    ngin_popSeg

    ngin_pushSeg "OBJECT_CONSTRUCT_HI"
    .local constructHi
    constructHi: .byte .hibyte( onConstructRtsAdjusted )
    ngin_popSeg

    ; Sanity check -- make sure each segment is tracking at the same address.
    .local relativeUpdateLo
    relativeUpdateLo = updateLo - __OBJECT_UPDATE_LO_RUN__
    .local relativeUpdateHi
    relativeUpdateHi = updateHi - __OBJECT_UPDATE_HI_RUN__
    .local relativeConstructLo
    relativeConstructLo = constructLo - __OBJECT_CONSTRUCT_LO_RUN__
    .local relativeConstructHi
    relativeConstructHi = constructHi - __OBJECT_CONSTRUCT_HI_RUN__
    .assert relativeUpdateLo = relativeUpdateHi .and \
            relativeUpdateLo = relativeConstructLo .and \
            relativeUpdateLo = relativeConstructHi, error
    .assert relativeConstructLo = relativeConstructHi, error
    .assert relativeUpdateLo < \
            ::ngin_Object_kMaxObjectTypes, \
        error, .sprintf( "no more than %d object types can be defined", \
                         ::ngin_Object_kMaxObjectTypes )

    ; Set the object type ID symbol.
    ::identifier = .lobyte( relativeUpdateLo )

    ; Add a trampoline for update.
    .proc __ngin_update
        jsr         onRender
        ; Object ID may have been trashed by onRender.
        ldx         ngin_Object_current
        ngin_jsrRts onUpdate
    .endproc
.endmacro

.macro ngin_Object_endDefine
    .endscope
    .undefine __ngin_Object_define_identifier
.endmacro

.global __ngin_Object_data

.define __ngin_Object_other( typeId, element ) \
    ~~( __ngin_Object_data + ::ngin_Object_kDataStride * \
      ( __ngin_Object_declare_structIdentifier {typeId}::element ) )

; ngin_Object_other can be used to access data members of other object types
; (rather than those of the current object type).
; \note "~~" (two bitwise NOTs) are used to make sure that the syntax doesn't
;       match indirect addressing. E.g. LDA ngin_Object_other foo, bar, Y
;       would otherwise generate LDA (ind), Y
; \note In case offsets are needed for "element", they should be added after the
;       element identifier (e.g. element+1, not 1+element).
.define ngin_Object_other( typeId, element ) \
    ~~( __ngin_stride {ngin_Object_kDataStride} + \
        __ngin_Object_other {typeId}, {element} )

; ngin_Object_this can be used to access data members of the current object
; type.
.define ngin_Object_this( element ) \
    ngin_Object_other {__ngin_Object_define_identifier}, {element}

; Current object ID
.global ngin_Object_current

.macro __ngin_Object_new_constructorParameter offset, param
    .if .not .blank( {param} )
        ngin_mov8 __ngin_Object_constructorParameters + \
            ngin_Object_ConstructorParameters::custom + (offset), {param}
    .endif
.endmacro

; Allocates a new object instance of type typeId.
; Returns the allocated object ID, or ngin_Object_kInvalidId if allocation
; failed.
.global __ngin_Object_new
.global __ngin_Object_new_typeId
.assert ngin_Object_kMaxCustomConstructorParameters = 2, error
.macro ngin_Object_new typeId, position_, param1, param2
    __ngin_requireParameter {typeId}, "typeId"

    ; All parameters except the typeId are optional.

    .if .not .blank( {position_} )
        ngin_mov32 __ngin_Object_constructorParameters + \
            ngin_Object_ConstructorParameters::position, {position_}
    .endif
    __ngin_Object_new_constructorParameter 0, {param1}
    __ngin_Object_new_constructorParameter 1, {param2}

    ; \todo Probably best to pass in a register
    ngin_mov8 __ngin_Object_new_typeId, {typeId}

    jsr __ngin_Object_new
.endmacro

; Frees an object referenced by objectId.
.global __ngin_Object_free
.macro ngin_Object_free objectId
    __ngin_requireParameter {objectId}, "objectId"

    ; If X register is passed, no need to load.
    .if .not .xmatch( {objectId}, x )
        ldx objectId
    .endif

    jsr __ngin_Object_free
.endmacro

; Updates all active objects.
.global __ngin_Object_updateAll
.macro ngin_Object_updateAll
    jsr __ngin_Object_updateAll
.endmacro

.endif
