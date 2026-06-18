# CMake build for RPCEmu (SA-1110 fork)
#
# A modern, qmake-independent build. Mirrors src/qt5/rpcemu.pro.
#
#   cmake -S . -B build -DRPCEMU_DYNAREC=ON
#   cmake --build build -j"$(nproc)"
#
# The resulting rpcemu-recompiler / rpcemu-interpreter binary is placed in the
# project root (run it from a directory containing your roms/ folder).
#
# Options:
#   -DRPCEMU_DYNAREC=ON|OFF   Recompiler (default) vs portable interpreter
#
# Builds against Qt 6 (default) or Qt 5 (-DRPCEMU_QT_VERSION=5). Both are
# supported: the audio backend (src/qt5/plt_sound.cpp) and the GUI use
# QT_VERSION guards to handle the Qt 6 (QAudioSink) and Qt 5 (QAudioOutput)
# multimedia APIs.

cmake_minimum_required(VERSION 3.16)
project(rpcemu C CXX)

option(RPCEMU_DYNAREC "Build the ARM->x86 dynarec recompiler (x86 hosts only)" ON)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# Match the qmake build's strictness.
add_compile_options(-Werror=switch -fno-common -Wall -Wextra)

# Qt. AUTOMOC/AUTORCC replace the qmake moc/rcc steps.
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
# Default to Qt 6; pass -DRPCEMU_QT_VERSION=5 to build against Qt 5. Both
# compile and run (the Qt-version differences are handled with QT_VERSION
# guards in src/qt5/plt_sound.{cpp,h} and src/qt5/main_window.cpp).
set(RPCEMU_QT_VERSION 6 CACHE STRING "Qt major version to build against (5 or 6)")
find_package(Qt${RPCEMU_QT_VERSION} REQUIRED COMPONENTS Core Widgets Gui Multimedia)
set(QT_VERSION_MAJOR ${RPCEMU_QT_VERSION})
message(STATUS "Building against Qt ${Qt${RPCEMU_QT_VERSION}_VERSION}")

# --- Emulator core (C) -------------------------------------------------------
set(CORE_SOURCES
	src/superio.c src/cdrom-iso.c src/cmos.c src/cp15.c src/fdc.c src/fpa.c
	src/hostfs.c src/ide.c src/iomd.c src/keyboard.c src/mem.c src/romload.c
	src/rpcemu.c src/sound.c src/vidc20.c src/podules.c src/podulerom.c
	src/icside.c src/rpc-machdep.c src/arm_common.c src/i8042.c
	src/disc.c src/disc_adf.c src/disc_hfe.c src/disc_mfm_common.c
)

# --- NAT networking via bundled SLiRP ---------------------------------------
set(SLIRP_SOURCES
	src/slirp/bootp.c src/slirp/cksum.c src/slirp/cutils.c src/slirp/if.c
	src/slirp/ip_icmp.c src/slirp/ip_input.c src/slirp/ip_output.c
	src/slirp/mbuf.c src/slirp/misc.c src/slirp/sbuf.c src/slirp/slirp.c
	src/slirp/socket.c src/slirp/tcp_input.c src/slirp/tcp_output.c
	src/slirp/tcp_subr.c src/slirp/tcp_timer.c src/slirp/udp.c
)

# --- Platform glue (Linux/Unix) ---------------------------------------------
set(PLATFORM_SOURCES
	src/network-nat.c src/network-linux.c src/network.c src/broadcast_relay.c
	src/cdrom-linuxioctl.c
	src/hostfs-unix.c src/rpc-linux.c
	src/qt5/keyboard_x.c
)

# --- Qt front-end (C++) ------------------------------------------------------
set(GUI_SOURCES
	src/qt5/settings.cpp src/qt5/rpc-qt5.cpp src/qt5/main_window.cpp
	src/qt5/configure_dialog.cpp src/qt5/about_dialog.cpp src/qt5/plt_sound.cpp
	src/qt5/nat_edit_dialog.cpp src/qt5/nat_list_dialog.cpp
	src/qt5/network_dialog.cpp
	src/qt5/icon.qrc src/qt5/resources.qrc
)

# --- CPU execution engine: dynarec or interpreter ---------------------------
if(RPCEMU_DYNAREC)
	set(TARGET_NAME rpcemu-recompiler)
	set(ENGINE_SOURCES src/ArmDynarec.c)
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		list(APPEND ENGINE_SOURCES src/codegen_amd64.c)
	else()
		list(APPEND ENGINE_SOURCES src/codegen_x86.c)
	endif()
else()
	set(TARGET_NAME rpcemu-interpreter)
	set(ENGINE_SOURCES src/arm.c src/codegen_null.c)
endif()

add_executable(${TARGET_NAME}
	${CORE_SOURCES} ${SLIRP_SOURCES} ${PLATFORM_SOURCES}
	${GUI_SOURCES} ${ENGINE_SOURCES}
)

target_include_directories(${TARGET_NAME} PRIVATE src src/qt5 src/slirp)
target_compile_definitions(${TARGET_NAME} PRIVATE CONFIG_SLIRP)

target_link_libraries(${TARGET_NAME} PRIVATE
	Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Widgets
	Qt${QT_VERSION_MAJOR}::Gui Qt${QT_VERSION_MAJOR}::Multimedia
)

find_package(OpenGL)
if(OpenGL_FOUND)
	target_link_libraries(${TARGET_NAME} PRIVATE OpenGL::GL)
endif()
find_package(Threads REQUIRED)
target_link_libraries(${TARGET_NAME} PRIVATE Threads::Threads)

# Place the binary in the project root, matching the qmake build (DESTDIR=../..).
set_target_properties(${TARGET_NAME} PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}"
)
