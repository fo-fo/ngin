ngin_addSample( ngin-sample-sprite-animation
    sprite-animation.s
)

ngin_addSpriteAsset( ngin-sample-sprite-animation-sprites
    OUTFILE sprites
    IMAGE   ryu.gif
    SYMBOL  animation_ryu
)

target_link_libraries( ngin-sample-sprite-animation
    ngin-sample-sprite-animation-sprites
)
