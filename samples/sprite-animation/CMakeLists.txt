ngin_addSample( ngin-sample-sprite-animation
    sprite-animation.s
)

ngin_spriteAssetLibrary( ngin-sample-sprite-animation-sprites OUTFILE sprites )
    # Events must appear before the sprite to which they are applied.
    ngin_spriteAssetEvent( ON_FRAME 1 CALLBACK onFrame1 )
    ngin_spriteAsset( IMAGE ryu.gif SYMBOL animation_ryu DELAY 10 )
ngin_endSpriteAssetLibrary()

target_link_libraries( ngin-sample-sprite-animation
    ngin-sample-sprite-animation-sprites
)
