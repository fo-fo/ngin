ngin_addSample( ngin-sample-imported-sprite
    imported-sprite.s
)

ngin_spriteAssetLibrary( ngin-sample-imported-sprite-sprites OUTFILE sprites )
    ngin_spriteAsset( IMAGE sprite.png SYMBOL sprite HFLIP VFLIP HVFLIP )
ngin_endSpriteAssetLibrary()

ngin_paletteAssetLibrary( ngin-sample-imported-sprite-palettes OUTFILE palettes )
    ngin_paletteAsset( IMAGE sprite.png SYMBOL sprite_pal )
ngin_endPaletteAssetLibrary()

target_link_libraries( ngin-sample-imported-sprite
    ngin-sample-imported-sprite-sprites
    ngin-sample-imported-sprite-palettes
)
