add_subdirectory( assets )

ngin_addSample( ngin-sample-map
    map.s

    # From assets:
    $<TARGET_OBJECTS:ngin-sample-map-maps>
)
