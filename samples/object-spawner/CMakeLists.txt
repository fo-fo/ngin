add_subdirectory( assets )

ngin_addSample( ngin-sample-object-spawner
    object-spawner.s

    # From assets:
    $<TARGET_OBJECTS:ngin-sample-object-spawner-maps>
)
