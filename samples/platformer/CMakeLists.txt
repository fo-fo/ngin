add_subdirectory( assets )

ngin_addSample( ngin-sample-platformer
    platformer.s
    object-player.s
)

target_link_libraries( ngin-sample-platformer
    # From assets:
    ngin-sample-platformer-maps
    ngin-sample-platformer-sprites
)
