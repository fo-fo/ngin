ngin_addSample( ngin-sample-imported-sprite
    imported-sprite.s
)

ngin_addSpriteAsset( ngin-sample-imported-sprite-sprites
    OUTFILE sprites
    IMAGES  sprite.png
    SYMBOLS sprite
)

target_link_libraries( ngin-sample-imported-sprite
    ngin-sample-imported-sprite-sprites
)
