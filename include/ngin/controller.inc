.if .not .defined( NGIN_CONTROLLER_INC_INCLUDED )
NGIN_CONTROLLER_INC_INCLUDED = 1

.enum ngin_Controller
    kA      =         %1
    kB      =        %10
    kSelect =       %100
    kStart  =      %1000
    kUp     =    %1_0000
    kDown   =   %10_0000
    kLeft   =  %100_0000
    kRight  = %1000_0000
.endenum

.global __ngin_Controller_read1
.macro ngin_Controller_read1
    jsr __ngin_Controller_read1
.endmacro

.global __ngin_Controller_read2
.macro ngin_Controller_read2
    jsr __ngin_Controller_read2
.endmacro

.global __ngin_Controller_readFast1
.macro ngin_Controller_readFast1
    jsr __ngin_Controller_readFast1
.endmacro

.global __ngin_Controller_readFast2
.macro ngin_Controller_readFast2
    jsr __ngin_Controller_readFast2
.endmacro

.endif
