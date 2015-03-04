.include "ngin/controller.inc"
.include "blargg-read-joy.inc"

kControllerIndex = 1

readJoy:
    blargg_readJoy_template ::kControllerIndex

readJoyFast:
    blargg_readJoyFast_template ::kControllerIndex

__ngin_Controller_read2      := readJoy
__ngin_Controller_readFast2  := readJoyFast
