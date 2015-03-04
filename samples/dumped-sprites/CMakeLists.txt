ngin_addSample( ngin-sample-dumped-sprites
    dumped-sprites.s
)

add_subdirectory( data )

add_dependencies( ngin-sample-dumped-sprites
    ngin-sample-dumped-sprites-data )
