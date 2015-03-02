add_library( ngin STATIC
    linker-config-dummy.s
    reset.s
    vectors.s
    ines-header.s
    ppu.s
    shadow-oam.s
    sprite-renderer.s
    memory.s
    memory/copy-memory.s
    memory/copy-port.s
    memory/copy-memory-to-port.s
    memory/copy-port-to-memory.s
    memory/fill-memory.s
    memory/fill-port.s
    ppu-buffer.s
)

# \note Debug info is added to the release build also, because might as well.
set( __ngin_compileFlags
    "-t none -g --feature underline_in_numbers --feature c_comments \
--asm-include-dir ${CMAKE_SOURCE_DIR}/include --cpu 6502x"
)
set( __ngin_linkerConfig "linker/nrom.cfg" )
set( __ngin_sourceDir ${CMAKE_CURRENT_SOURCE_DIR} )

set_target_properties( ngin
    PROPERTIES
        COMPILE_FLAGS "${__ngin_compileFlags}"
)

# Export to parent scope.
set( __ngin_compileFlags ${__ngin_compileFlags} PARENT_SCOPE )
set( __ngin_linkerConfig ${__ngin_linkerConfig} PARENT_SCOPE )
set( __ngin_sourceDir ${__ngin_sourceDir} PARENT_SCOPE )

set_source_files_properties( linker-config-dummy.s
    PROPERTIES
        OBJECT_DEPENDS ${__ngin_sourceDir}/${__ngin_linkerConfig}
)

function( ngin_addSample name )
    add_executable( ${name} ${ARGN} )

    set_target_properties( ${name}
        PROPERTIES
            OUTPUT_NAME ${name}.nes
            COMPILE_FLAGS "${__ngin_compileFlags}"
            # \note --force-import is needed to bring in object files from the
            #       static library which would be otherwise stripped.
            # \todo Test the verbose map switch (-vm) to see how it differs.
            LINK_FLAGS "-t none -C ${__ngin_sourceDir}/${__ngin_linkerConfig} \
--force-import __ngin_vectors --force-import __ngin_inesHeader \
-Wl --dbgfile,${CMAKE_CURRENT_BINARY_DIR}/${name}.nes.dbg \
-m ${name}-map.txt"
    )

    target_link_libraries( ${name}
        ngin
    )

    # Add a custom target to start an emulator.
    add_custom_target(
        "start-${name}"
        COMMAND
            ${__ngin_emulatorExecutable} ${CMAKE_CURRENT_BINARY_DIR}/${name}.nes
        DEPENDS ${name}
        # \note NintendulatorDX v36 or later is required for this to work,
        #       older versions will not find the source files relative to the
        #       current working directory.
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Running ${name}"
        VERBATIM
    )
endfunction()
