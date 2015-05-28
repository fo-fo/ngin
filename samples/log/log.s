.include "ngin/ngin.inc"

ngin_bss blah: .res 5

; An object declaration just to test the stride stuff:

ngin_Object_declare object_Test
    foo     .word
ngin_Object_endDeclare

ngin_Object_define object_Test
    .proc onConstruct
        ngin_log debug, "onConstruct"
        ngin_mov16 { ngin_Object_this foo, x }, #12345
        rts
    .endproc

    .proc onRender
        ngin_log debug, "onRender"
        rts
    .endproc

    .proc onUpdate
        ngin_log debug, "logging from onUpdate; this.foo=%d", \
                        { 16 : ngin_Object_this foo, x }

        rts
    .endproc
ngin_Object_endDefine

ngin_entryPoint start
.proc start
    lda #55
    sta blah
    lda #$66
    sta blah+1
    lda #$77
    sta blah+2
    lda #$88
    sta blah+3
    lda #$99
    sta blah+4

    lda #69
    ldx #70
    ldy #71
    ngin_log debug, "foo a=%d x=%d y=%d imm=%d start=$%4X blah=%d", \
                    a, x, y, #111, #start, blah

    ldx #1
    ngin_log debug, "x relative (size 16): blah,x(when x=%d)=$%4X", \
                    x, { 16 : blah, x }

    ldy #2
    ngin_log debug, "y relative (size 24): blah,y(when y=%d)=$%08X", \
                    y, { 24 : blah, y }

    ngin_Object_new #object_Test
    ngin_Object_updateAll

    jmp *
.endproc
