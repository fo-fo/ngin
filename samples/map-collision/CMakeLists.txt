add_subdirectory( assets )

ngin_addSample( ngin-sample-map-collision
    map-collision.s
)

target_link_libraries( ngin-sample-map-collision
    # From assets:
    ngin-sample-map-collision-maps
)
