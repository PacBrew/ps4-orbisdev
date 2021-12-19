cmake_minimum_required(VERSION 3.7)

###################################################################

if (NOT DEFINED ENV{ORBISDEV})
    set(ORBISDEV /opt/pacbrew/ps4/orbisdev)
else ()
    set(ORBISDEV $ENV{ORBISDEV})
endif ()

list(APPEND CMAKE_MODULE_PATH "${ORBISDEV}/cmake")

set(PS4 TRUE)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR "x86_64")
set(CMAKE_CROSSCOMPILING 1)

set(CMAKE_ASM_COMPILER ${ORBISDEV}/bin/orbis-as CACHE PATH "")
set(CMAKE_C_COMPILER ${ORBISDEV}/bin/clang CACHE PATH "")
set(CMAKE_CXX_COMPILER ${ORBISDEV}/bin/clang++ CACHE PATH "")
set(CMAKE_LINKER ${ORBISDEV}/bin/orbis-ld CACHE PATH "")
set(CMAKE_AR ${ORBISDEV}/bin/orbis-ar CACHE PATH "")
set(CMAKE_RANLIB ${ORBISDEV}/bin/orbis-ranlib CACHE PATH "")
set(CMAKE_STRIP ${ORBISDEV}/bin/orbis-strip CACHE PATH "")

set(CMAKE_LIBRARY_ARCHITECTURE x86_64 CACHE INTERNAL "abi")

set(CMAKE_FIND_ROOT_PATH ${ORBISDEV} ${ORBISDEV}/usr)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "Shared libs not available")

###################################################################

set(PS4_ARCH_SETTINGS "--target=x86_64-scei-ps4")
set(PS4_COMMON_INCLUDES "-I${ORBISDEV}/usr/include -I${ORBISDEV}/usr/include/orbis -isystem ${ORBISDEV} -isysroot ${ORBISDEV}")
set(PS4_COMMON_FLAGS "${PS4_ARCH_SETTINGS} -D__PS4__ -D__ORBIS__ ${PS4_COMMON_INCLUDES}")
set(PS4_COMMON_LIBS "-L${ORBISDEV}/lib -L${ORBISDEV}/usr/lib")

set(CMAKE_C_FLAGS_INIT "${PS4_COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${PS4_COMMON_FLAGS} -I${ORBISDEV}/usr/include/c++/v1")
set(CMAKE_ASM_FLAGS_INIT "${PS4_COMMON_FLAGS}")

set(PS4_LINKER_FLAGS "${ORBISDEV}/usr/lib/crt0.o -T ${ORBISDEV}/usr/lib/linker.x -Wl,--dynamic-linker=/libexec/ld-elf.so.1 -Wl,--gc-sections -z max-page-size=0x4000 -pie -Wl,--eh-frame-hdr")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${PS4_ARCH_SETTINGS} ${PS4_COMMON_LIBS} ${PS4_LINKER_FLAGS} -lkernel_stub -lSceLibcInternal_stub")

# Start find_package in config mode
set(CMAKE_FIND_PACKAGE_PREFER_CONFIG TRUE)

# Set pkg-config for the same
find_program(PKG_CONFIG_EXECUTABLE NAMES orbis-pkg-config HINTS "${ORBISDEV}/usr/bin")
if (NOT PKG_CONFIG_EXECUTABLE)
    message(WARNING "Could not find orbis-pkg-config: try installing ps4-pkg-config")
endif ()

function(add_self project)
    add_custom_command(
            OUTPUT "${project}.self"
            COMMAND ${CMAKE_COMMAND} -E env "ORBISDEV=${ORBISDEV}" "${ORBISDEV}/bin/orbis-elf-create" "${project}" "${project}.oelf"
            COMMAND "python" "${ORBISDEV}/bin/make_fself.py" "--auth-info" "000000000000000000000000001C004000FF000000000080000000000000000000000000000000000000008000400040000000000000008000000000000000080040FFFF000000F000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" "${project}.oelf" "${project}.self"
            VERBATIM
    )
    add_custom_target(
            "${project}_self" ALL
            DEPENDS "${project}"
            DEPENDS "${project}.self"
    )
endfunction()

function(add_pkg project pkgdir)
    add_custom_command(
            OUTPUT "${project}.pkg"
            COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_BINARY_DIR}/${project}.self" "${pkgdir}/eboot.bin"
            COMMAND "${ORBISDEV}/bin/pkgTool" "pkg_build" "${pkgdir}/Project.gp4" "${pkgdir}/pkg"
            VERBATIM
    )
    add_custom_target(
            "${project}_pkg" ALL
            DEPENDS "${project}_self"
    )
endfunction()