# \note Currently relying on the fact that compilation order of the files
#       determines the order in which ngin_Lua_require is processed within
#       the files (required for config/reset). This is brittle.
add_library( ngin STATIC
    ${CMAKE_CURRENT_BINARY_DIR}/config.generated.s
    # These files are not compiled into the library, and are instead
    # compiled separately for each project:
    # linker-config-dummy.s
    # ines-header.s
    reset.s
    vectors.s
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
    build-log.s
    force-import.s
    controller/controller-common.s
    controller/controller1.s
    controller/controller2.s
    collision.s
    map-data.s
    map-scroller.s
    nmi.s
    map-collision.s
    camera.s
    lfsr8.s
    object.s
    force-segment.s
    object-spawner.s
    debug/upload-debug-palette.s
    sprite-animator.s
    log.s
    assert.s
    sound/muse/muse.s
    sound/ngin-muse.s
    irq.s
    alloc.s
    mapper/nrom.s
    mapper/fme-7.s
)

file( RELATIVE_PATH generatedIncludeDirRelative ${CMAKE_BINARY_DIR}
    "${CMAKE_CURRENT_BINARY_DIR}/../../include" )

# \note "CACHE INTERNAL" variables are basically global variables. This is
#       required because ngin_addExecutable and other functions always need
#       access to them.
# \note Debug info is added to the release build also, because might as well.
set( __ngin_compileFlags
    "-t none -g --feature underline_in_numbers --feature c_comments \
--asm-include-dir ${PROJECT_SOURCE_DIR}/include \
--asm-include-dir ${generatedIncludeDirRelative} \
--cpu 6502x"
     CACHE INTERNAL "__ngin_compileFlags"
)
set( __ngin_sourceDir ${CMAKE_CURRENT_SOURCE_DIR}
     CACHE INTERNAL "__ngin_sourceDir" )

set_target_properties( ngin
    PROPERTIES
        COMPILE_FLAGS "${__ngin_compileFlags}"
)
