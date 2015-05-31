ngin_addSample( ngin-sample-sprite-animation
    sprite-animation.s
)

ngin_spriteAssetLibrary( ngin-sample-sprite-animation-sprites OUTFILE sprites )
    ngin_spriteAsset( IMAGE ryu.gif SYMBOL animation_ryu )
ngin_endSpriteAssetLibrary()

target_link_libraries( ngin-sample-sprite-animation
    ngin-sample-sprite-animation-sprites
)
