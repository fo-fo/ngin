ngin_spriteAssetLibrary( ngin-sample-platformer-sprites OUTFILE sprites 8X16 )
    # Player:
    ngin_spriteAsset( IMAGE animation-player-stand.gif   HFLIP )
    ngin_spriteAsset( IMAGE animation-player-run.gif     HFLIP )
    ngin_spriteAsset( IMAGE animation-player-attack.gif  HFLIP )

    # Ball:
    ngin_spriteAsset( IMAGE animation-ball-stand.png )
ngin_endSpriteAssetLibrary()
