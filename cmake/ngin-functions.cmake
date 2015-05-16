include( CMakeParseArguments )

set( __ngin_toolsRoot ${__ngin_rootDir}/tools )

# \todo Make it possible to specify the segment for the common data and each
#       map separately.
# \todo If SYMBOLS are left empty, use the MAPS filenames with extension stripped
#       (and underscore placement) as the symbol.
# OUTFILE:  Prefix for the output filenames
# MAPS:     List of TMX maps that should be imported
# SYMBOLS:  List of symbols corresponding to each map listed in MAPS
# DEPENDS:  Additional dependencies (e.g. tileset images/files)
function( ngin_addMapAssets target )
    cmake_parse_arguments(
        TOOLARGS
        ""                              # Options
        "OUTFILE"                       # One-value arguments
        "MAPS;SYMBOLS;DEPENDS"          # Multi-value arguments
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
            ${TOOLARGS_DEPENDS}
        WORKING_DIRECTORY
            ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT
            "tiled-map-importer.py: Importing ${TOOLARGS_MAPS}"
        VERBATIM
    )

    add_library( ${target}
        ${TOOLARGS_OUTFILE}.s
    )

    file( RELATIVE_PATH currentBinaryDirRelative ${CMAKE_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR} )

    set_target_properties( ${target}
        PROPERTIES
            COMPILE_FLAGS "${__ngin_compileFlags} \
--asm-include-dir ${currentBinaryDirRelative} \
--bin-include-dir ${currentBinaryDirRelative}"
    )
endfunction()
