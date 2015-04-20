cmake_minimum_required( VERSION 3.0 )

project( ngin ASM )

# \todo May not be required, could open the .nes file with the default
#       tool based on extension? (Or: if left empty, use the default)
set( __ngin_emulatorExecutable
    "C:/Program Files (x86)/nintendulatordx/nintendulator"
)

# Spaces in paths are too much trouble to make them worth our while, so check
# for them.
if ( ${CMAKE_SOURCE_DIR} MATCHES " " )
    message( FATAL_ERROR "[ngin] sorry, can't handle spaces in CMAKE_SOURCE_DIR" )
endif()

if ( ${CMAKE_BINARY_DIR} MATCHES " " )
    message( FATAL_ERROR "[ngin] sorry, can't handle spaces in CMAKE_BINARY_DIR" )
endif()

set( __ngin_rootDir ${CMAKE_CURRENT_SOURCE_DIR} )

include( cmake/ngin-functions.cmake )

add_subdirectory( src/ngin )
add_subdirectory( samples )
