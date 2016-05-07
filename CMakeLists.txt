cmake_minimum_required( VERSION 3.0 )

# If PROJECT_NAME is defined, assume that we're being built as a subproject.
# Note that this will only work if project() appeared before add_subdirectory.
if ( DEFINED PROJECT_NAME )
    message( STATUS "[ngin] being built as a subproject of '${PROJECT_NAME}'" )
    set( __ngin_isSubproject TRUE )
endif()

project( ngin ASM )

# Spaces in paths are too much trouble to make them worth our while, so check
# for them.
if ( ${CMAKE_SOURCE_DIR} MATCHES " " )
    message( FATAL_ERROR "[ngin] sorry, can't handle spaces in CMAKE_SOURCE_DIR" )
endif()

if ( ${CMAKE_BINARY_DIR} MATCHES " " )
    message( FATAL_ERROR "[ngin] sorry, can't handle spaces in CMAKE_BINARY_DIR" )
endif()

# \note PROJECT_SOURCE_DIR/PROJECT_BINARY_DIR is equivalent to
# CMAKE_SOURCE_DIR/CMAKE_BINARY_DIR, unless we're being built as a subproject.
if ( ${PROJECT_SOURCE_DIR} MATCHES " " )
    message( FATAL_ERROR "[ngin] sorry, can't handle spaces in PROJECT_SOURCE_DIR" )
endif()

if ( ${PROJECT_BINARY_DIR} MATCHES " " )
    message( FATAL_ERROR "[ngin] sorry, can't handle spaces in PROJECT_BINARY_DIR" )
endif()

set( __ngin_rootDir ${CMAKE_CURRENT_SOURCE_DIR} )

include( cmake/ngin-find-tools.cmake )
include( cmake/ngin-functions.cmake )

# -------------------------------------------------------------------------
# Configuration:

function( __ngin_setDefault variable value )
    if ( NOT ${variable} )
        set( ${variable} ${value} PARENT_SCOPE )
    endif()
endfunction()

# Defaults that should work for every mirroring setting (see map-data.lua).
__ngin_setDefault( ngin_cfg_MapData_viewWidth          256-8 )
__ngin_setDefault( ngin_cfg_MapData_viewHeight         240-8 )
__ngin_setDefault( ngin_cfg_MapData_attrViewWidth      256-16 )
__ngin_setDefault( ngin_cfg_MapData_attrViewHeight     240-16 )

configure_file( include/ngin/config.in.inc include/ngin/config.generated.inc )
configure_file( src/ngin/config.in.s src/ngin/config.generated.s )
configure_file( src/ngin/config.in.lua src/ngin/config.generated.lua )

# -------------------------------------------------------------------------

add_subdirectory( src/ngin )

# Only build samples if we're not being built as a subproject.
if ( NOT __ngin_isSubproject )
    add_subdirectory( samples )
endif()
