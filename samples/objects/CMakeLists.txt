add_subdirectory( assets )

ngin_addSample( ngin-sample-objects
    objects.s
    object-ball.s
)

target_link_libraries( ngin-sample-objects
    # From assets:
    ngin-sample-objects-maps
)
