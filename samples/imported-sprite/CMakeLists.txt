ngin_addSample( ngin-sample-imported-sprite
    imported-sprite.s
)

ngin_addSpriteAsset( ngin-sample-imported-sprite-sprites
    OUTFILE sprites
    IMAGE   sprite.png
    SYMBOL  sprite
)

target_link_libraries( ngin-sample-imported-sprite
    ngin-sample-imported-sprite-sprites
)
