include( CMakeParseArguments )

set( __ngin_toolsRoot ${__ngin_rootDir}/tools )

# -----------------------------------------------------------------------------

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
            COMPILE_FLAGS "\
${__ngin_compileFlags} \
--asm-include-dir ${currentBinaryDirRelative} \
--bin-include-dir ${currentBinaryDirRelative}"
    )
endfunction()

# -----------------------------------------------------------------------------

function( ngin_spriteAssetLibrary target )
    cmake_parse_arguments(
        TOOLARGS
        "8X16"                          # Options
        "OUTFILE"                       # One-value arguments
        ""                              # Multi-value arguments
        ${ARGN}
    )

    # Take note of the variables. They will be applied in
    # ngin_endSpriteAssetLibrary.

    set( __ngin_spriteAsset_extraArgs "" )
    if ( TOOLARGS_8X16 )
        list( APPEND __ngin_spriteAsset_extraArgs --8x16 )
    endif()

    # Export to parent scope.
    set( __ngin_spriteAsset_extraArgs ${__ngin_spriteAsset_extraArgs} PARENT_SCOPE )
    set( __ngin_spriteAsset_target ${target} PARENT_SCOPE )
    set( __ngin_spriteAsset_outfile ${TOOLARGS_OUTFILE} PARENT_SCOPE )
    set( __ngin_spriteAsset_images  "" PARENT_SCOPE )
    set( __ngin_spriteAsset_depends "" PARENT_SCOPE )
    set( __ngin_spriteAsset_args    "" PARENT_SCOPE )
endfunction()

function( ngin_spriteAsset )
    cmake_parse_arguments(
        TOOLARGS
        "HFLIP;VFLIP;HVFLIP"            # Options
        ""                              # One-value arguments
        "IMAGE;SYMBOL;DEPENDS"          # Multi-value arguments
        ${ARGN}
    )

    # If empty, figure out a symbol based on the file name.
    if ( "${TOOLARGS_SYMBOL}" STREQUAL "" )
        # Remove the extension.
        get_filename_component( TOOLARGS_SYMBOL ${TOOLARGS_IMAGE} NAME_WE )

        # Turn it into a C-compatible identifier.
        string( MAKE_C_IDENTIFIER ${TOOLARGS_SYMBOL} TOOLARGS_SYMBOL )
    endif()

    list( APPEND __ngin_spriteAsset_images ${TOOLARGS_IMAGE} )
    list( APPEND __ngin_spriteAsset_depends ${TOOLARGS_DEPENDS} )

    if ( TOOLARGS_HFLIP )
        list( APPEND __ngin_spriteAsset_args "--hflip" )
    endif()

    if ( TOOLARGS_VFLIP )
        list( APPEND __ngin_spriteAsset_args "--vflip" )
    endif()

    if ( TOOLARGS_HVFLIP )
        list( APPEND __ngin_spriteAsset_args "--hvflip" )
    endif()

    list( APPEND __ngin_spriteAsset_args
        -s ${TOOLARGS_SYMBOL}
        -i ${TOOLARGS_IMAGE}
    )

    # Export to parent scope.
    set( __ngin_spriteAsset_images ${__ngin_spriteAsset_images} PARENT_SCOPE )
    set( __ngin_spriteAsset_depends ${__ngin_spriteAsset_depends} PARENT_SCOPE )
    set( __ngin_spriteAsset_args ${__ngin_spriteAsset_args} PARENT_SCOPE )
endfunction()

function( ngin_endSpriteAssetLibrary )
    set( spriteImporter
        ${__ngin_toolsRoot}/sprite-importer/sprite-importer.py
    )

    add_custom_command(
        OUTPUT
            ${__ngin_spriteAsset_outfile}.s
            ${__ngin_spriteAsset_outfile}.inc
            ${__ngin_spriteAsset_outfile}.chr
        COMMAND
            python ${spriteImporter}
            ${__ngin_spriteAsset_args}
            -o ${CMAKE_CURRENT_BINARY_DIR}/${__ngin_spriteAsset_outfile}
            ${__ngin_spriteAsset_extraArgs}
        DEPENDS
            ${spriteImporter}
            # \todo May need to expand to full path to avoid UB?
            ${__ngin_spriteAsset_images}
            ${__ngin_spriteAsset_depends}
        WORKING_DIRECTORY
            ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT
            "sprite-importer.py: Importing ${__ngin_spriteAsset_images}"
        VERBATIM
    )

    add_library( ${__ngin_spriteAsset_target}
        ${__ngin_spriteAsset_outfile}.s
    )

    file( RELATIVE_PATH currentBinaryDirRelative ${CMAKE_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR} )

    set_target_properties( ${__ngin_spriteAsset_target}
        PROPERTIES
            COMPILE_FLAGS "\
${__ngin_compileFlags} \
--asm-include-dir ${currentBinaryDirRelative} \
--bin-include-dir ${currentBinaryDirRelative}"
    )
endfunction()

# -----------------------------------------------------------------------------

function( ngin_museSoundAssetLibrary target )
    # \todo Options for segments (song segments, DPCM segment, etc)
    cmake_parse_arguments(
        TOOLARGS
        ""                              # Options
        "OUTFILE"                       # One-value arguments
        ""                              # Multi-value arguments
        ${ARGN}
    )

    # Export to parent scope.
    set( __ngin_museSoundAsset_target ${target} PARENT_SCOPE )
    set( __ngin_museSoundAsset_outfile ${TOOLARGS_OUTFILE} PARENT_SCOPE )
    set( __ngin_museSoundAsset_songs        "" PARENT_SCOPE )
    set( __ngin_museSoundAsset_soundEffects "" PARENT_SCOPE )
    set( __ngin_museSoundAsset_symbols      "" PARENT_SCOPE )
    set( __ngin_museSoundAsset_depends      "" PARENT_SCOPE )
endfunction()

function( ngin_museSongAsset )
    cmake_parse_arguments(
        TOOLARGS
        ""                              # Options
        ""                              # One-value arguments
        "SONG;SYMBOL;DEPENDS"           # Multi-value arguments
        ${ARGN}
    )

    # If empty, figure out a symbol based on the file name.
    if ( "${TOOLARGS_SYMBOL}" STREQUAL "" )
        # Remove the extension.
        get_filename_component( TOOLARGS_SYMBOL ${TOOLARGS_SONG} NAME_WE )

        # Turn it into a C-compatible identifier.
        string( MAKE_C_IDENTIFIER ${TOOLARGS_SYMBOL} TOOLARGS_SYMBOL )
    endif()

    list( APPEND __ngin_museSoundAsset_songs   ${TOOLARGS_SONG} )
    list( APPEND __ngin_museSoundAsset_symbols ${TOOLARGS_SYMBOL} )
    list( APPEND __ngin_museSoundAsset_depends ${TOOLARGS_DEPENDS} )

    # Export to parent scope.
    set( __ngin_museSoundAsset_songs   ${__ngin_museSoundAsset_songs}   PARENT_SCOPE )
    set( __ngin_museSoundAsset_symbols ${__ngin_museSoundAsset_symbols} PARENT_SCOPE )
    set( __ngin_museSoundAsset_depends ${__ngin_museSoundAsset_depends} PARENT_SCOPE )
endfunction()

function( ngin_museSoundEffectAsset )
    cmake_parse_arguments(
        TOOLARGS
        ""                              # Options
        ""                              # One-value arguments
        "EFFECT;SYMBOL;DEPENDS"         # Multi-value arguments
        ${ARGN}
    )

    # If empty, figure out a symbol based on the file name.
    if ( "${TOOLARGS_SYMBOL}" STREQUAL "" )
        # Remove the extension.
        get_filename_component( TOOLARGS_SYMBOL ${TOOLARGS_EFFECT} NAME_WE )

        # Turn it into a C-compatible identifier.
        string( MAKE_C_IDENTIFIER ${TOOLARGS_SYMBOL} TOOLARGS_SYMBOL )
    endif()

    list( APPEND __ngin_museSoundAsset_soundEffects ${TOOLARGS_EFFECT} )
    list( APPEND __ngin_museSoundAsset_symbols      ${TOOLARGS_SYMBOL} )
    list( APPEND __ngin_museSoundAsset_depends      ${TOOLARGS_DEPENDS} )

    # Export to parent scope.
    set( __ngin_museSoundAsset_soundEffects ${__ngin_museSoundAsset_soundEffects} PARENT_SCOPE )
    set( __ngin_museSoundAsset_symbols      ${__ngin_museSoundAsset_symbols} PARENT_SCOPE )
    set( __ngin_museSoundAsset_depends      ${__ngin_museSoundAsset_depends} PARENT_SCOPE )
endfunction()

function( ngin_endMuseSoundAssetLibrary )
    set( musetrackerImporter
        ${__ngin_toolsRoot}/musetracker-importer/musetracker-importer.py
    )

    set( allInputs
        ${__ngin_museSoundAsset_songs}
        ${__ngin_museSoundAsset_soundEffects}
    )

    add_custom_command(
        OUTPUT
            ${__ngin_museSoundAsset_outfile}.s
            ${__ngin_museSoundAsset_outfile}.inc
        COMMAND
            python ${musetrackerImporter}
            -i ${__ngin_museSoundAsset_songs}
            -e ${__ngin_museSoundAsset_soundEffects}
            -s ${__ngin_museSoundAsset_symbols}
            -o ${CMAKE_CURRENT_BINARY_DIR}/${__ngin_museSoundAsset_outfile}
        DEPENDS
            ${musetrackerImporter}
            # \todo May need to expand to full path to avoid UB?
            ${__ngin_museSoundAsset_songs}
            ${__ngin_museSoundAsset_soundEffects}
            ${__ngin_museSoundAsset_depends}
        WORKING_DIRECTORY
            ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT
            "musetracker-importer.py: Importing ${allInputs}"
        VERBATIM
    )

    add_library( ${__ngin_museSoundAsset_target}
        ${__ngin_museSoundAsset_outfile}.s
    )

    file( RELATIVE_PATH currentBinaryDirRelative ${CMAKE_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR} )

    # \todo Factor out to a function.
    set_target_properties( ${__ngin_museSoundAsset_target}
        PROPERTIES
            COMPILE_FLAGS "\
${__ngin_compileFlags} \
--asm-include-dir ${currentBinaryDirRelative} \
--bin-include-dir ${currentBinaryDirRelative}"
    )
endfunction()
