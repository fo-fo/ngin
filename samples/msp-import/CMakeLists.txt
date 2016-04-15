ngin_addSample( ngin-sample-msp-import
    msp-import.s
)

ngin_mspAssetLibrary( ngin-sample-msp-import-sprites OUTFILE sprites )
    ngin_mspAsset( MSP data/sprites.msp SYMBOL_PREFIX sprite )
ngin_endMspAssetLibrary()

target_link_libraries( ngin-sample-msp-import
    ngin-sample-msp-import-sprites
)
