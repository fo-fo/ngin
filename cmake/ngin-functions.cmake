include( CMakeParseArguments )

set( __ngin_toolsRoot ${__ngin_rootDir}/tools )

# \todo Make it possible to specify the segment for the common data and each
#       map separately.
function( ngin_addMapAssets target )
    cmake_parse_arguments(
        TOOLARGS
        ""                              # Options
        "OUTFILE"                       # One-value arguments
        "MAPS;SYMBOLS"                  # Multi-value arguments
        ${ARGN}
    )

    set( tiledMapImporter
        ${__ngin_toolsRoot}/tiled-map-importer/tiled-map-importer.py
    )

    # \todo Check that TOOLARGS_OUTFILE is not empty, and that length of
    #       TOOLARGS_MAPS is equal to length of TOOLARGS_SYMBOLS.
    # \todo Make sure that all dependencies and missing outputs cause a
    #       recompile properly.
    add_custom_command(
        OUTPUT
            ${TOOLARGS_OUTFILE}.s
            ${TOOLARGS_OUTFILE}.inc
            ${TOOLARGS_OUTFILE}.chr
        COMMAND
            python ${tiledMapImporter}
            -i ${TOOLARGS_MAPS}
            -s ${TOOLARGS_SYMBOLS}
            -o ${CMAKE_CURRENT_BINARY_DIR}/${TOOLARGS_OUTFILE}
        DEPENDS
            ${tiledMapImporter}
            # \todo May need to expand to full path to avoid UB?
            ${TOOLARGS_MAPS}
        WORKING_DIRECTORY
            ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT
            "Running tiled-map-importer.py"
        VERBATIM
    )

    add_library( ${target} OBJECT
        ${TOOLARGS_OUTFILE}.s
    )
endfunction()
