add_subdirectory( assets )

ngin_addSample( ngin-sample-object-spawner
    object-spawner.s
)

target_link_libraries( ngin-sample-object-spawner
    # From assets:
    ngin-sample-object-spawner-maps
)
