add_subdirectory( assets )

ngin_addSample( ngin-sample-map-collision
    map-collision.s

    # From assets:
    $<TARGET_OBJECTS:ngin-sample-map-collision-maps>
)
