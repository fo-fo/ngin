.include "reset.inc"

.proc __ngin_reset
    ; \todo Proper reset code

    ; __ngin_start is defined in the user application with the ngin_entryPoint
    ; macro.
    .import __ngin_start
    jmp __ngin_start
.endproc
