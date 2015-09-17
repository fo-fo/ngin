# \todo May want to use "FindPythonInterp"
find_program( __ngin_python
    python
    HINTS
        ${__ngin_rootDir}/deps/python
)

if ( NOT __ngin_python )
    message( FATAL_ERROR "Python was not found" )
endif()

message( STATUS "Found Python: ${__ngin_python}" )

# -----------------------------------------------------------------------------

find_program( __ngin_ndx
    Nintendulator
    HINTS
        ${__ngin_rootDir}/deps/nintendulatordx
        "C:/Program Files (x86)/nintendulatordx"
)

if ( NOT __ngin_ndx )
    message( FATAL_ERROR "NDX was not found" )
endif()

message( STATUS "Found NDX: ${__ngin_ndx}" )

# -----------------------------------------------------------------------------

find_program( __ngin_musetracker
    Musetracker
    HINTS
        ${__ngin_rootDir}/deps/musetracker
        "C:/Program Files (x86)/musetracker"
)

if ( NOT __ngin_musetracker )
    message( FATAL_ERROR "Musetracker was not found" )
endif()

message( STATUS "Found Musetracker: ${__ngin_musetracker}" )

# -----------------------------------------------------------------------------
