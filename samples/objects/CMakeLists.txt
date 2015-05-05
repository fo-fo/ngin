add_subdirectory( assets )

ngin_addSample( ngin-sample-objects
    objects.s
    object-ball.s

    # From assets:
    $<TARGET_OBJECTS:ngin-sample-objects-maps>
)
