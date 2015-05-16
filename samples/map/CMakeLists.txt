add_subdirectory( assets )

ngin_addSample( ngin-sample-map
    map.s
)

target_link_libraries( ngin-sample-map
    # From assets:
    ngin-sample-map-maps
)
