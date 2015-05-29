.include "ngin/object.inc"
.include "ngin/branch.inc"
.include "ngin/log.inc"

.segment "NGIN_BSS"

; Index of the object that is currently being updated
ngin_Object_current:                    .byte 0

; Function parameters:
__ngin_Object_new_typeId:               .byte 0

; Object constructor parameters (shared by all objects):
__ngin_Object_constructorParameters:    .tag ngin_Object_ConstructorParameters

; Data for each active object
__ngin_Object_data:                     .res ngin_Object_kMaxActiveObjects * \
                                             ngin_Object_kMaxObjectDataSize

; For each active object, link to the next object in the free list
; Only valid for objects that are free.
nextObject:                             .res ngin_Object_kMaxActiveObjects

; For each active object, type of the object
objectType:                             .res ngin_Object_kMaxActiveObjects

; Linked list of free objects
freeObjects:                            .byte 0

.segment "NGIN_CODE"

; \todo Make this public to allow re-initialization?
ngin_constructor __ngin_Object_construct
.proc __ngin_Object_construct
    ; Initialize all objects. Build a linked list of all of the objects, then
    ; connect them to the freeObjects list root.

    ngin_log debug, "Object.construct()"

    .assert ngin_Object_kMaxActiveObjects > 0, error
    ldx #ngin_Object_kMaxActiveObjects
    loop:
        txa
        sta nextObject-1, x
        lda #ngin_Object_kInvalidTypeId
        sta objectType-1, x
        dex
    ngin_branchIfNotZero loop

    ; Terminate the list.
    ngin_mov8 nextObject + ngin_Object_kMaxActiveObjects-1, \
              #ngin_Object_kInvalidId

    ; Connect free list to the first object.
    ngin_mov8 freeObjects, #0

    ngin_mov8 ngin_Object_current, #0

    rts
.endproc

.proc __ngin_Object_new
    typeId := __ngin_Object_new_typeId

    ldx freeObjects
    cpx #ngin_Object_kInvalidId
    beq noFreeObjectIdsLeft
        ; Allocate the object (index in X). Adjust the root of freeObjects list
        ; to the next object from the free list.
        ldy nextObject, x
        sty freeObjects

        ngin_log debug, \
            "Object.new(): allocated object: typeId=%d, instanceId=%d", \
            typeId, x

        ; Set the object type.
        lda typeId
        sta objectType, x

        ; Set the current object ID for constructor.
        stx ngin_Object_current

        ; Call the constructor for the object (depends on type) by using RTS.
        ; \note This "call" will not return here (it will return to the call
        ;       site of __ngin_Object_new)
        tay
        lda __OBJECT_CONSTRUCT_HI_RUN__, y
        pha
        lda __OBJECT_CONSTRUCT_LO_RUN__, y
        pha
        rts

    noFreeObjectIdsLeft:

    ngin_log debug, "Object.new(): no free object IDs left"

    ; No free objects left. Return ngin_Object_kInvalidId in X as an
    ; error indicator.
    ; \todo Provide alternate mode where an object (of specified type(s)?) is
    ;       hijacked if none are free. Or an alternate function for that
    ;       behavior. And maybe also an alternative which can't fail, but will
    ;       trip in emulator if there are no free objects left.

    rts
.endproc

.proc __ngin_Object_free
    ; Insert the freed object (in X) to the front of the freeObjects list.

    ; \todo Runtime assert to make sure that the object in X doesn't already
    ;       have type "invalid".

    ngin_log debug, "Object.free(): freeing instanceId=%d", x

    ; Point the freed object at the head of the freeObjects list.
    ngin_mov8 { nextObject, x }, freeObjects

    ; Point the freeObjects list at the freed object.
    stx freeObjects

    ; Set the freed object's type to invalid (so that updateAll will ignore it).
    ngin_mov8 { objectType, x }, #ngin_Object_kInvalidTypeId

    rts
.endproc

.proc __ngin_Object_updateAll
    ; Update all objects. We don't keep a list of allocated objects, so
    ; this just loops over all objects and checks if their type is valid.

    ; \todo If "new" is called in constructor, or the update routine,
    ;       ngin_Object_current will get replaced with the ID of the new
    ;       object. Should save them in a stack. This is actually a serious
    ;       problem right now because updateAll depends on
    ;       ngin_Object_current staying unchanged.

    __ngin_bss loopCount: .byte 0
    ngin_mov8 loopCount, #ngin_Object_kMaxActiveObjects

    ; The code below depends on the number of objects being 8 at the moment.
    ; \todo Support other number of objects.
    .assert ngin_Object_kMaxActiveObjects = 8, error

    loop:
        ldx ngin_Object_current
        ldy objectType, x
        cpy #ngin_Object_kInvalidTypeId
        beq invalidId
            ; Not invalid, call the update routine.
            jsr updateTrampoline
        invalidId:

        lda ngin_Object_current
        clc
        adc #5
        and #7
        sta ngin_Object_current
        dec loopCount
    ngin_branchIfNotZero loop

    ; Change the first object on every frame.
    lda ngin_Object_current
    clc
    adc #3
    and #7
    sta ngin_Object_current

    rts

    .proc updateTrampoline
        lda __OBJECT_UPDATE_HI_RUN__, y
        pha
        lda __OBJECT_UPDATE_LO_RUN__, y
        pha
        rts
    .endproc
.endproc
