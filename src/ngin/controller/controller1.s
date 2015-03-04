.include "ngin/controller.inc"
.include "blargg-read-joy.inc"

kControllerIndex = 0

readJoy:
    blargg_readJoy_template ::kControllerIndex

readJoyFast:
    blargg_readJoyFast_template ::kControllerIndex

__ngin_Controller_read1      := readJoy
__ngin_Controller_readFast1  := readJoyFast
