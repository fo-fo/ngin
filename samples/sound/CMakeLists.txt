ngin_addSample( ngin-sample-sound
    sound.s
)

ngin_museSoundAssetLibrary( ngin-sample-sound-sounds OUTFILE sounds )
    ngin_museSongAsset       ( SONG   sound/test-song.pom )
    ngin_museSoundEffectAsset( EFFECT sound/break.pom )
    ngin_museSoundEffectAsset( EFFECT sound/checkpoint.pom )
ngin_endMuseSoundAssetLibrary()

target_link_libraries( ngin-sample-sound
    ngin-sample-sound-sounds
)
