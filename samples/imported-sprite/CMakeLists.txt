ngin_addSample( ngin-sample-imported-sprite
    imported-sprite.s
)

ngin_spriteAssetLibrary( ngin-sample-imported-sprite-sprites OUTFILE sprites )
    ngin_spriteAsset( IMAGE sprite.png SYMBOL sprite HFLIP VFLIP HVFLIP )
ngin_endSpriteAssetLibrary()

target_link_libraries( ngin-sample-imported-sprite
    ngin-sample-imported-sprite-sprites
)
