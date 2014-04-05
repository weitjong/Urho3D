#
# Copyright (c) 2008-2014 the Urho3D project.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

# Define all supported build options
include (CMakeDependentOption)
option (ANDROID "Setup build for Android platform")
option (RASPI "Setup build for Raspberry Pi platform")
option (IOS "Setup build for iOS platform")
option (URHO3D_64BIT "Enable 64-bit build")
option (URHO3D_ANGELSCRIPT "Enable AngelScript scripting support" TRUE)
option (URHO3D_LUA "Enable additional Lua scripting support")
option (URHO3D_LUAJIT "Enable Lua scripting support using LuaJIT (check LuaJIT's CMakeLists.txt for more options)")
option (URHO3D_SSE "Enable SSE instruction set" TRUE)
if (CMAKE_PROJECT_NAME STREQUAL Urho3D)
    cmake_dependent_option (URHO3D_LUAJIT_AMALG "Enable LuaJIT amalgamated build (LuaJIT only)" FALSE "URHO3D_LUAJIT" FALSE)
    cmake_dependent_option (URHO3D_SAFE_LUA "Enable Lua C++ wrapper safety checks (Lua scripting only)" FALSE "URHO3D_LUA OR URHO3D_LUAJIT" FALSE)
    option (URHO3D_SAMPLES "Build sample applications")
    cmake_dependent_option (URHO3D_TOOLS "Build standalone tools (Desktop and RPI only; on Android only build Lua standalone tools)" TRUE "NOT IOS;NOT ANDROID OR URHO3D_LUA OR URHO3D_LUAJIT" FALSE)
    cmake_dependent_option (URHO3D_EXTRAS "Build extras (Desktop and RPI only)" FALSE "NOT IOS AND NOT ANDROID" FALSE)
    option (URHO3D_DOCS "Generate documentation as part of normal build")
    option (URHO3D_DOCS_QUIET "Generate documentation as part of normal build, suppress generation process from sending anything to stdout")
    cmake_dependent_option (URHO3D_MINIDUMPS "Enable minidumps on crash (VS only)" TRUE "MSVC" FALSE)
    option (URHO3D_FILEWATCHER "Enable filewatcher support" TRUE)
endif ()
option (URHO3D_PROFILING "Enable profiling support" TRUE)
option (URHO3D_LOGGING "Enable logging support" TRUE)
option (URHO3D_TESTING "Enable testing support")
if (URHO3D_TESTING)
    set (URHO3D_TEST_TIME_OUT 5 CACHE STRING "Number of seconds to test run the executables")
else ()
    unset (URHO3D_TEST_TIME_OUT CACHE)
endif ()
if (MSVC)
    option (URHO3D_OPENGL "Use OpenGL instead of Direct3D (Windows platform only)")
elseif (WIN32)
    option (URHO3D_OPENGL "Use OpenGL instead of Direct3D (Windows platform only)" TRUE)
endif ()
cmake_dependent_option (URHO3D_MKLINK "Use mklink command to create symbolic links (Windows Vista and above only)" FALSE "WIN32" FALSE)
cmake_dependent_option (URHO3D_STATIC_RUNTIME "Use static C/C++ runtime libraries and eliminate the need for runtime DLLs installation (VS only)" FALSE "MSVC" FALSE)
set (URHO3D_LIB_TYPE STATIC CACHE STRING "Specify Urho3D library type, possible values are STATIC (default) and SHARED")
if (CMAKE_CROSSCOMPILING AND NOT ANDROID)
    set (URHO3D_SCP_TO_TARGET "" CACHE STRING "Use scp to transfer executables to target system (non-Android cross-compiling build only), SSH digital key must be setup first for this to work, typical value has a pattern of usr@tgt:remote-loc")
else ()
    unset (URHO3D_SCP_TO_TARGET CACHE)
endif ()
if (ANDROID)
    set (ANDROID_ABI armeabi-v7a CACHE STRING "Specify ABI for native code (Android build only), possible values are armeabi-v7a (default) and armeabi")
else ()
    unset (ANDROID_ABI CACHE)
endif ()

# Set the build type if not explicitly set, for single-configuration generator only
if (CMAKE_GENERATOR STREQUAL Xcode)
    set (XCODE TRUE)
endif ()
if (NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    set (CMAKE_BUILD_TYPE Release)
endif ()
if (CMAKE_HOST_WIN32)
    execute_process (COMMAND uname -o RESULT_VARIABLE UNAME_EXIT_CODE OUTPUT_VARIABLE UNAME_OPERATING_SYSTEM ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
    if (UNAME_EXIT_CODE EQUAL 0 AND UNAME_OPERATING_SYSTEM STREQUAL Msys)
        set (MSYS 1)
    endif ()
endif ()

# Enable testing
if (URHO3D_TESTING)
    enable_testing ()
    add_definitions (-DURHO3D_TESTING)
endif ()

# Enable SSE instruction set. Requires Pentium III or Athlon XP processor at minimum.
if (URHO3D_SSE)
    add_definitions (-DURHO3D_SSE)
endif ()

# Enable structured exception handling and minidumps on MSVC only.
if (MSVC AND URHO3D_MINIDUMPS)
    add_definitions (-DURHO3D_MINIDUMPS)
endif ()

# By default use the MSVC dynamic runtime. To eliminate the need to distribute the runtime installer,
# this can be switched off if not using Urho3D as a shared library.
if (MSVC)
    if (URHO3D_STATIC_RUNTIME)
        set (RELEASE_RUNTIME /MT)
        set (DEBUG_RUNTIME /MTd)
    else ()
        set (RELEASE_RUNTIME "")
        set (DEBUG_RUNTIME "")
    endif ()
endif ()

# Enable file watcher support for automatic resource reloads by default.
if (URHO3D_FILEWATCHER)
    add_definitions (-DURHO3D_FILEWATCHER)
endif ()

# Enable profiling by default. If disabled, autoprofileblocks become no-ops and the Profiler subsystem is not instantiated.
if (URHO3D_PROFILING)
    add_definitions (-DURHO3D_PROFILING)
endif ()

# Enable logging by default. If disabled, LOGXXXX macros become no-ops and the Log subsystem is not instantiated.
if (URHO3D_LOGGING)
    add_definitions (-DURHO3D_LOGGING)
endif ()

# If not on MSVC, enable use of OpenGL instead of Direct3D9 (either not compiling on Windows or
# with a compiler that may not have an up-to-date DirectX SDK). This can also be unconditionally
# enabled, but Windows graphics card drivers are usually better optimized for Direct3D. Direct3D can
# be manually enabled for MinGW with -DURHO3D_OPENGL=0, but is likely to fail due to missing headers
# and libraries, unless the MinGW-w64 distribution is used.
if (NOT MSVC)
    if (NOT WIN32 OR NOT DEFINED URHO3D_OPENGL)
        set (URHO3D_OPENGL 1)
    endif ()
endif ()
if (URHO3D_OPENGL)
    add_definitions (-DURHO3D_OPENGL)
endif ()

# If not on Windows, enable Unix mode for kNet library.
if (NOT WIN32)
    add_definitions (-DUNIX)
endif ()

# Add definitions for GLEW
if (NOT IOS AND NOT ANDROID AND NOT RASPI AND URHO3D_OPENGL)
    add_definitions (-DGLEW_STATIC -DGLEW_NO_GLU)
endif ()

# Add definition for AngelScript
if (URHO3D_ANGELSCRIPT)
    add_definitions (-DURHO3D_ANGELSCRIPT)
endif ()

# Default library type is STATIC
if (URHO3D_LIB_TYPE)
    string (TOUPPER ${URHO3D_LIB_TYPE} URHO3D_LIB_TYPE)
endif ()
if (NOT URHO3D_LIB_TYPE STREQUAL SHARED)
    set (URHO3D_LIB_TYPE STATIC)
    add_definitions (-DURHO3D_STATIC_DEFINE)
endif ()

# Add definition for amalgamated build
if (MSVC)
    if (URHO3D_LIB_TYPE STREQUAL SHARED)
        message (STATUS "Reverted back to non-amalgamated build because even conventional build of Urho3D shared library for MSVC is already a CMake-hack by itself")
        set (URHO3D_AMALG 0)
    elseif (URHO3D_AMALG LESS 3)
        set (URHO3D_AMALG 3)    # Force to autosplit to minimal 3 translation units to avoid symbols conflict
    endif ()
endif ()
if (URHO3D_AMALG)
    add_definitions (-DURHO3D_AMALG)
endif ()

# Add definition for Lua and LuaJIT
if (URHO3D_LUAJIT)
    add_definitions (-DURHO3D_LUAJIT)
    set (JIT JIT)
    # Implied URHO3D_LUA
    set (URHO3D_LUA 1)
    # Disable LuaJIT-specific amalgamated build when project-scope amalgamated build is enabled
    if (URHO3D_AMALG AND URHO3D_LUAJIT_AMALG)
        set (URHO3D_LUAJIT_AMALG 0)
    endif ()
endif ()
if (URHO3D_LUA)
    add_definitions (-DURHO3D_LUA)
endif ()

# Find DirectX SDK include & library directories if applicable
# Note: if a recent Windows SDK is installed instead, it will be possible to compile without;
# therefore do not log a fatal error in that case
if (WIN32)
    find_package (Direct3D)
    if (MSVC AND DIRECT3D_FOUND)
        # The headers in the SDK will be incompatible with MinGW, so only add the include directories when using Visual Studio
        include_directories (${DIRECT3D_INCLUDE_DIRS})
    endif ()
endif ()

# For Raspbery Pi, find Broadcom VideoCore IV firmware
if (RASPI)
    find_package (BCM_VC REQUIRED)
    include_directories (${BCM_VC_INCLUDE_DIRS})
endif ()

# Platform and compiler specific options
if (URHO3D_MODERN_CPP)
    add_definitions (-DURHO3D_MODERN_CPP)
    if (CMAKE_CXX_COMPILER_ID MATCHES GNU)
        # Use gnu++11/gnu++0x instead of c++11/c++0x as the latter does not work as expected when cross compiling
        execute_process (COMMAND ${CMAKE_COMMAND} -E touch test_modern_cpp.cpp)
        foreach (STANDARD gnu++11 gnu++0x)  # Fallback to gnu++0x on older GCC version
            execute_process (COMMAND ${CMAKE_CXX_COMPILER} -o test_modern_cpp.out -c test_modern_cpp.cpp -std=${STANDARD} RESULT_VARIABLE GCC_EXIT_CODE OUTPUT_QUIET ERROR_QUIET)
            if (GCC_EXIT_CODE EQUAL 0)
                set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=${STANDARD}")
                break ()
            endif ()
        endforeach ()
        if (NOT GCC_EXIT_CODE EQUAL 0)
            execute_process (COMMAND ${CMAKE_CXX_COMPILER} -dumpversion OUTPUT_VARIABLE GCC_VERSION ERROR_QUIET)
            message (FATAL_ERROR "Your GCC version ${GCC_VERSION} is too old to enable modern C++ support")
        endif ()
        execute_process (COMMAND ${CMAKE_COMMAND} -E remove test_modern_cpp.cpp test_modern_cpp.out)
    elseif (CMAKE_CXX_COMPILER_ID MATCHES Clang)
        # Cannot set CMAKE_CXX_FLAGS here directly because CMake uses the same flags for both C++ and Object-C languages, the latter does not support c++11 dialect
        # Workaround the problem by setting the compiler flags in the source properties for C++ language only in the setup_target() macro
        set (CLANG_CXX_FLAGS "-std=c++11 -stdlib=libc++")
        set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++")
    elseif (MSVC80)
        message (FATAL_ERROR "Your MSVC version is too told to enable experimental C++11 support")
    endif ()
endif ()
if (IOS)
    # IOS-specific setup
    add_definitions (-DIOS)
    if (URHO3D_64BIT)
        set (CMAKE_OSX_ARCHITECTURES $(ARCHS_STANDARD_INCLUDING_64_BIT))
    else ()
        set (CMAKE_OSX_ARCHITECTURES $(ARCHS_STANDARD_32_BIT))
    endif ()
    set (CMAKE_XCODE_EFFECTIVE_PLATFORMS -iphoneos -iphonesimulator)
    if (NOT MACOSX_BUNDLE_GUI_IDENTIFIER)
        set (MACOSX_BUNDLE_GUI_IDENTIFIER com.github.urho3d.\${PRODUCT_NAME:rfc1034identifier})
    endif ()
    set (CMAKE_OSX_SYSROOT iphoneos)    # Set Base SDK to "Latest iOS"
elseif (XCODE)
    # MacOSX-Xcode-specific setup
    if (NOT URHO3D_64BIT)
        set (CMAKE_OSX_ARCHITECTURES $(ARCHS_STANDARD_32_BIT))
    endif ()
    set (CMAKE_OSX_SYSROOT macosx)	# Set Base SDK to "Latest OS X"
    if (NOT CMAKE_OSX_DEPLOYMENT_TARGET)
        # If not set, set to current running build system OS version by default
        execute_process (COMMAND sw_vers -productVersion OUTPUT_VARIABLE CURRENT_OSX_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
        string (REGEX REPLACE ^\([^.]+\\.[^.]+\).* \\1 CMAKE_OSX_DEPLOYMENT_TARGET ${CURRENT_OSX_VERSION})
    endif ()
endif ()
if (MSVC)
    # Visual Studio-specific setup
    add_definitions (-D_CRT_SECURE_NO_WARNINGS)
    # Note: All CMAKE_xxx_FLAGS variables are not in list context (although they should be)
    set (CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${DEBUG_RUNTIME}")
    set (CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELEASE} ${RELEASE_RUNTIME} /fp:fast /Zi /GS-")
    set (CMAKE_C_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELWITHDEBINFO})
    set (CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${DEBUG_RUNTIME}")
    set (CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELEASE} ${RELEASE_RUNTIME} /fp:fast /Zi /GS- /D _SECURE_SCL=0")
    set (CMAKE_CXX_FLAGS_RELEASE ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
    # SSE flag is redundant if already compiling as 64bit
    if (URHO3D_SSE AND NOT URHO3D_64BIT)
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /arch:SSE")
        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:SSE")
    endif ()
    set (CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /OPT:REF /OPT:ICF /DEBUG")
    set (CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /OPT:REF /OPT:ICF")
    # Increase the addressing capacity when using amalgamated build
    if (URHO3D_AMALG)
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /bigobj")
        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /bigobj")
    endif ()
else ()
    # GCC/Clang-specific setup
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-invalid-offsetof")
    if (ANDROID)
        # Most of the flags are already setup in android.toolchain.cmake module
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstack-protector")
        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector")
        if (URHO3D_64BIT)
            # TODO: Revisit this again when ARM also support 64bit
            # For now just reference it to suppress "unused variable" warning
        endif ()
    elseif (IOS)
        # When performing CI build, suppress all the warnings for iOS build because 3rd party libraries produce too many of them and yet we don't want to touch the 3rd party library's source codes unnecessarily
        if ($ENV{CI})
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -w")
            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -w")
        endif ()
    else ()
        if (RASPI)
            add_definitions (-DRASPI)
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pipe -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -Wno-psabi")
            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pipe -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -Wno-psabi")
        else ()
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffast-math")
            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffast-math")
            if (URHO3D_64BIT)
                set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m64")
                set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m64")
            else ()
                set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
                set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
                if (URHO3D_SSE)
                    if (NOT WIN32)
                        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -msse")
                        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse")
                    else ()
                        message (STATUS "Using SSE2 instead of SSE because SSE fails on some Windows ports of GCC")
                        message (STATUS "Disable SSE with the CMake option -DURHO3D_SSE=0 if this is not desired")
                        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -msse2")
                        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse2")
                    endif ()
                endif ()
            endif ()
        endif ()
        # MinGW-specific setup
        if (WIN32)
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static -static-libgcc")
            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static -static-libstdc++ -static-libgcc")
            set (CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -static")
            # Additional compiler flags for Windows ports of GCC
            set (CMAKE_C_FLAGS_RELWITHDEBINFO "-O2 -g -DNDEBUG")
            set (CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g -DNDEBUG")
            # Reduce GCC optimization level from -O3 to -O2 for stability in RELEASE build type
            set (CMAKE_C_FLAGS_RELEASE "-O2 -DNDEBUG")
            set (CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG")
        endif ()
        set (CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DDEBUG -D_DEBUG")
        set (CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG -D_DEBUG")
    endif ()
    if (CMAKE_CXX_COMPILER_ID STREQUAL Clang AND CMAKE_GENERATOR STREQUAL Ninja)
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fcolor-diagnostics")
        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcolor-diagnostics")
    endif ()
endif ()

# Include CMake builtin module for building shared library support
include (GenerateExportHeader)

# Determine the project root directory
get_filename_component (PROJECT_ROOT_DIR ${PROJECT_SOURCE_DIR} PATH)

# Macro for setting common output directories
macro (set_output_directories OUTPUT_PATH)
    foreach (TYPE ${ARGN})
        set (CMAKE_${TYPE}_OUTPUT_DIRECTORY ${OUTPUT_PATH})
        foreach (CONFIG ${CMAKE_CONFIGURATION_TYPES})
            string (TOUPPER ${CONFIG} CONFIG)
            set (CMAKE_${TYPE}_OUTPUT_DIRECTORY_${CONFIG} ${OUTPUT_PATH})
        endforeach ()
    endforeach ()
endmacro ()

# Set common binary output directory for all targets
if (IOS)
    set (PLATFORM_PREFIX ios-)
elseif (CMAKE_CROSSCOMPILING)
    if (RASPI)
        set (PLATFORM_PREFIX raspi-)
    elseif (ANDROID)
        set (PLATFORM_PREFIX android-)      # Note: this is for Android tools (ARM arch) runtime binaries, Android libs output directory is not affected by this
    elseif (MINGW)
        set (PLATFORM_PREFIX mingw-)
    endif ()
endif ()
set_output_directories (${PROJECT_ROOT_DIR}/${PLATFORM_PREFIX}Bin RUNTIME PDB)

# Override builtin macro and function to suit our need, always generate header file regardless of target type...
macro (_DO_SET_MACRO_VALUES TARGET_LIBRARY)
    set (DEFINE_DEPRECATED)
    set (DEFINE_EXPORT)
    set (DEFINE_IMPORT)
    set (DEFINE_NO_EXPORT)

    if (COMPILER_HAS_DEPRECATED_ATTR)
        set (DEFINE_DEPRECATED "__attribute__ ((__deprecated__))")
    elseif (COMPILER_HAS_DEPRECATED)
        set (DEFINE_DEPRECATED "__declspec(deprecated)")
    endif ()

    get_property (type TARGET ${TARGET_LIBRARY} PROPERTY TYPE)

    if (type MATCHES "STATIC|SHARED")
        if (WIN32)
            set (DEFINE_EXPORT "__declspec(dllexport)")
            set (DEFINE_IMPORT "__declspec(dllimport)")
        elseif (COMPILER_HAS_HIDDEN_VISIBILITY AND USE_COMPILER_HIDDEN_VISIBILITY)
            set (DEFINE_EXPORT "__attribute__((visibility(\"default\")))")
            set (DEFINE_IMPORT "__attribute__((visibility(\"default\")))")
            set (DEFINE_NO_EXPORT "__attribute__((visibility(\"hidden\")))")
        endif ()
    endif ()
endmacro ()
# ... except, when target is a module library type
function (GENERATE_EXPORT_HEADER TARGET_LIBRARY)
    get_property (type TARGET ${TARGET_LIBRARY} PROPERTY TYPE)
    if (${type} MATCHES MODULE)
        message (WARNING "This macro should not be used with libraries of type MODULE")
        return ()
    endif ()
    _test_compiler_hidden_visibility ()
    _test_compiler_has_deprecated ()
    _do_set_macro_values (${TARGET_LIBRARY})
    _do_generate_export_header (${TARGET_LIBRARY} ${ARGN})
endfunction ()

# Override builtin function to suit our need, takes care of C flags as well as CXX flags
function (add_compiler_export_flags)
    if (NOT ANDROID AND NOT MSVC AND NOT DEFINED USE_COMPILER_HIDDEN_VISIBILITY AND NOT DEFINED COMPILER_HAS_DEPRECATED)
        message (STATUS "Following tests check whether compiler installed in this system has export/import and deprecated attributes support")
        message (STATUS "CMake will generate a suitable export header file for this system based on the test result")
        message (STATUS "It is OK to proceed to build Urho3D regardless of the test result")
    endif ()
    _test_compiler_hidden_visibility ()
    _test_compiler_has_deprecated ()

    if (NOT (USE_COMPILER_HIDDEN_VISIBILITY AND COMPILER_HAS_HIDDEN_VISIBILITY))
        # Just return if there are no flags to add.
        return ()
    endif ()

    set (EXTRA_FLAGS "-fvisibility=hidden")
    # Either return the extra flags needed in the supplied argument, or to the
    # CMAKE_C_FLAGS if no argument is supplied.
    if (ARGV1)
        set (${ARGV1} "${EXTRA_FLAGS}" PARENT_SCOPE)
    else ()
        set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${EXTRA_FLAGS}" PARENT_SCOPE)
    endif ()

    if (COMPILER_HAS_HIDDEN_INLINE_VISIBILITY)
        set (EXTRA_FLAGS "${EXTRA_FLAGS} -fvisibility-inlines-hidden")
    endif ()

    # Either return the extra flags needed in the supplied argument, or to the
    # CMAKE_CXX_FLAGS if no argument is supplied.
    if (ARGV0)
        set (${ARGV0} "${EXTRA_FLAGS}" PARENT_SCOPE)
    else ()
        set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${EXTRA_FLAGS}" PARENT_SCOPE)
    endif ()
endfunction ()

# Macro for precompiled headers
macro (enable_pch)
    if (MSVC)
        foreach (FILE ${SOURCE_FILES})
            if (FILE MATCHES \\.cpp$)
                if (FILE MATCHES Precompiled\\.cpp$)
                    set_source_files_properties (${FILE} PROPERTIES COMPILE_FLAGS "/YcPrecompiled.h")
                else ()
                    set_source_files_properties (${FILE} PROPERTIES COMPILE_FLAGS "/YuPrecompiled.h")
                endif ()
            endif ()
        endforeach ()
    else ()
        # TODO: to enable usage of precompiled header in GCC, for now just make sure the correct Precompiled.h is found in the search
        foreach (FILE ${SOURCE_FILES})
            if (FILE MATCHES Precompiled\\.h$)
                get_filename_component (PATH ${FILE} PATH)
                include_directories (${PATH})
                break ()
            endif ()
        endforeach ()
    endif ()
endmacro ()

# Macro for setting up dependency lib for compilation and linking of a target
macro (setup_target)
    # Include directories
    include_directories (${LIBS} ${INCLUDE_DIRS_ONLY})
    # Link libraries
    define_dependency_libs (${TARGET_NAME})
    string (REGEX REPLACE \\.\\./|ThirdParty/|Engine/|Extras/|/include|/src "" STRIP_LIBS "${LIBS};${LINK_LIBS_ONLY}")
    target_link_libraries (${TARGET_NAME} ${ABSOLUTE_PATH_LIBS} ${STRIP_LIBS})

    # Workaround CMake/Xcode generator bug where it always appends '/build' path element to SYMROOT attribute and as such the items in Products are always rendered as red as if they are not yet built
    if (XCODE)
        file (MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/build)
        get_target_property (LOCATION ${TARGET_NAME} LOCATION)
        string (REGEX REPLACE "^.*\\$\\(CONFIGURATION\\)" $(CONFIGURATION) SYMLINK ${LOCATION})
        get_filename_component (DIRECTORY ${SYMLINK} PATH)
        add_custom_command (TARGET ${TARGET_NAME} POST_BUILD
            COMMAND mkdir -p ${DIRECTORY} && ln -s -f $<TARGET_FILE:${TARGET_NAME}> ${DIRECTORY}/$<TARGET_FILE_NAME:${TARGET_NAME}>
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/build)
    endif ()

    # Workaround CMake problem of sharing CMAKE_CXX_FLAGS for both C++ and Objective-C languages
    if (CLANG_CXX_FLAGS)
        foreach (FILE ${SOURCE_FILES})
            if (FILE MATCHES \\.cpp|\\.cc)
                set_source_files_properties (${FILE} PROPERTIES COMPILE_FLAGS "${CLANG_CXX_FLAGS}")
            endif ()
        endforeach ()
    endif ()
endmacro ()

# Macro for setting up a library target
macro (setup_library)
    prepare_amalgamated_build ()
    add_library (${TARGET_NAME} ${ARGN} ${SOURCE_FILES})
    setup_target ()

    if (CMAKE_PROJECT_NAME STREQUAL Urho3D)
        if (NOT ${TARGET_NAME} STREQUAL Urho3D)
            # Only interested in static library type, i.e. exclude shared and module library types
            get_target_property (LIB_TYPE ${TARGET_NAME} TYPE)
            if (LIB_TYPE MATCHES STATIC)
                set (STATIC_LIBRARY_TARGETS ${STATIC_LIBRARY_TARGETS} ${TARGET_NAME} PARENT_SCOPE)
            endif ()
        endif ()
        if (URHO3D_LIB_TYPE STREQUAL SHARED)
            set_target_properties (${TARGET_NAME} PROPERTIES COMPILE_DEFINITIONS URHO3D_EXPORTS)
        endif ()
    endif ()
endmacro ()

# Macro for setting up an executable target
#  NODEPS - setup executable target without defining Urho3D dependency libraries
#  WIN32/MACOSX_BUNDLE/EXCLUDE_FROM_ALL - see CMake help on add_executable command
macro (setup_executable)
    # Parse extra arguments
    cmake_parse_arguments (ARG "NODEPS" "" "" ${ARGN})

    add_executable (${TARGET_NAME} ${ARG_UNPARSED_ARGUMENTS} ${SOURCE_FILES})
    if (ARG_NODEPS)
        define_dependency_libs (Urho3D-nodeps)
    else ()
        define_dependency_libs (Urho3D)
    endif ()
    setup_target ()
    
    if (IOS)
        set_target_properties (${TARGET_NAME} PROPERTIES XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2")
    elseif (CMAKE_CROSSCOMPILING AND NOT ANDROID AND URHO3D_SCP_TO_TARGET)
        add_custom_command (TARGET ${TARGET_NAME} POST_BUILD COMMAND scp $<TARGET_FILE:${TARGET_NAME}> ${URHO3D_SCP_TO_TARGET} || exit 0)
    endif ()
    if (DEST_RUNTIME_DIR)
        # Need to check if the variable is defined first because this macro could be called by CMake project outside of Urho3D that does not wish to install anything
        install (TARGETS ${TARGET_NAME} RUNTIME DESTINATION ${DEST_RUNTIME_DIR} BUNDLE DESTINATION ${DEST_RUNTIME_DIR})
    endif ()
endmacro ()

# Macro for setting up linker flags for Mac OS X desktop build
macro (setup_macosx_linker_flags LINKER_FLAGS)
    set (${LINKER_FLAGS} "${${LINKER_FLAGS}} -framework AudioUnit -framework Carbon -framework Cocoa -framework CoreAudio -framework ForceFeedback -framework IOKit -framework OpenGL -framework CoreServices")
endmacro ()

# Macro for setting up linker flags for IOS build
macro (setup_ios_linker_flags LINKER_FLAGS)
    set (${LINKER_FLAGS} "${${LINKER_FLAGS}} -framework AudioToolbox -framework CoreAudio -framework CoreGraphics -framework Foundation -framework OpenGLES -framework QuartzCore -framework UIKit")
endmacro ()

# Macro for adding SDL native init function on Android platform
macro (add_android_native_init)
    # This source file could not be added when building SDL static library because it needs SDL_Main() which is not yet available at library building time
    # The SDL_Main() is defined by Android application that could be resided in other CMake projects outside of Urho3D CMake project which makes things a little bit complicated
    if (CMAKE_PROJECT_NAME STREQUAL Urho3D)
        list (APPEND SOURCE_FILES ${PROJECT_ROOT_DIR}/Source/ThirdParty/SDL/src/main/android/SDL_android_main.c)
    elseif (EXISTS ${URHO3D_HOME}/Source/ThirdParty/SDL/src/main/android/SDL_android_main.c)
        # Use Urho3D source installation
        list (APPEND SOURCE_FILES ${URHO3D_HOME}/Source/ThirdParty/SDL/src/main/android/SDL_android_main.c)
    elseif (EXISTS ${CMAKE_PREFIX_PATH}/share/${PATH_SUFFIX}/templates/android/SDL_android_main.c)
        # Use Urho3D SDK installation on non-default installation location (PATH_SUFFIX variable is set in FindUrho3D.cmake module)
        list (APPEND SOURCE_FILES ${CMAKE_PREFIX_PATH}/share/${PATH_SUFFIX}/templates/android/SDL_android_main.c)
    elseif (EXISTS ${CMAKE_INSTALL_PREFIX}/share/${PATH_SUFFIX}/templates/android/SDL_android_main.c)
        # Use Urho3D SDK installation on system default installation location
        list (APPEND SOURCE_FILES ${CMAKE_INSTALL_PREFIX}/share/${PATH_SUFFIX}/templates/android/SDL_android_main.c)
    else ()
        message (FATAL_ERROR
            "Could not find SDL_android_main.c source file in default SDK installation location or Urho3D project root tree. "
            "For searching in a non-default Urho3D SDK installation, use 'URHO3D_INSTALL_PREFIX' environment variable to specify the prefix path of the installation location. "
            "For searching in a source tree of Urho3D project, use 'URHO3D_HOME' environment variable to specify the Urho3D project root directory.")
    endif ()
endmacro ()

# Macro for setting up an executable target with resources to copy
macro (setup_main_executable)
    # Define resource files
    if (XCODE)
        set (RESOURCE_FILES ${PROJECT_ROOT_DIR}/Bin/CoreData ${PROJECT_ROOT_DIR}/Bin/Data)
        set_source_files_properties (${RESOURCE_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
        list (APPEND SOURCE_FILES ${RESOURCE_FILES})
    endif ()

    if (ANDROID)
        # Add SDL native init function, SDL_Main() entry point must be defined by one of the source files in ${SOURCE_FILES} 
        add_android_native_init ()
        # Setup shared library output path
        set_output_directories (${ANDROID_LIBRARY_OUTPUT_PATH} LIBRARY)
        # Setup target as main shared library
        define_dependency_libs (Urho3D)
        setup_library (SHARED)
        # Copy other dependent shared libraries to Android library output path
        foreach (FILE ${ABSOLUTE_PATH_LIBS})
            get_filename_component (EXT ${FILE} EXT)
            if (EXT STREQUAL .so)
                get_filename_component (NAME ${FILE} NAME)
                add_custom_command (TARGET ${TARGET_NAME} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} ARGS -E copy_if_different ${FILE} ${ANDROID_LIBRARY_OUTPUT_PATH}
                    COMMENT "Copying ${NAME} to library output directory")
            endif ()
        endforeach ()
        # Strip target main shared library
        add_custom_command (TARGET ${TARGET_NAME} POST_BUILD
            COMMAND ${CMAKE_STRIP} $<TARGET_FILE:${TARGET_NAME}>
            COMMENT "Stripping lib${TARGET_NAME}.so in library output directory")
        # When performing packaging, include the final apk file
        if (CMAKE_PROJECT_NAME STREQUAL Urho3D AND NOT APK_INCLUDED)
            install (FILES ${LIBRARY_OUTPUT_PATH_ROOT}/bin/Urho3D.apk DESTINATION ${DEST_RUNTIME_DIR} OPTIONAL)
            set (APK_INCLUDED 1)
        endif ()
    else ()
        # Setup target as executable
        if (WIN32)
            set (EXE_TYPE WIN32)
        elseif (IOS)
            set (EXE_TYPE MACOSX_BUNDLE)
            setup_ios_linker_flags (CMAKE_EXE_LINKER_FLAGS)
        elseif (APPLE)
            setup_macosx_linker_flags (CMAKE_EXE_LINKER_FLAGS)
        endif ()
        prepare_amalgamated_build (FINALIZED)
        setup_executable (${EXE_TYPE})
        if (WIN32)
            set_target_properties (${TARGET_NAME} PROPERTIES DEBUG_POSTFIX _d)
        endif ()
    endif ()
    
    if (IOS)
        get_target_property (TARGET_LOC ${TARGET_NAME} LOCATION)
        # Define a custom target to check for resource modification
        string (REGEX REPLACE /Contents/MacOS "" TARGET_LOC ${TARGET_LOC})    # The regex replacement is temporary workaround to correct the wrong location caused by CMake/Xcode generator bug
        add_custom_target (RESOURCE_CHECK_${TARGET_NAME} ALL
            \(\( `find ${RESOURCE_FILES} -newer ${TARGET_LOC} 2>/dev/null |wc -l` \)\) && touch -cm ${SOURCE_FILES} || exit 0
            COMMENT "Checking for changes in the Resource folders")
        add_dependencies (${TARGET_NAME} RESOURCE_CHECK_${TARGET_NAME})
    endif ()
endmacro ()

# Macro for adjusting target output name by dropping _suffix from the target name
macro (adjust_target_name)
    string (REGEX REPLACE _.*$ "" OUTPUT_NAME ${TARGET_NAME})
    set_target_properties (${TARGET_NAME} PROPERTIES OUTPUT_NAME ${OUTPUT_NAME})
endmacro ()

# Macro for defining external library dependencies
# The purpose of this macro is emulate CMake to set the external library dependencies transitively
# It works for both targets setup within Urho3D project and outside Urho3D project that uses Urho3D as external static/shared library
macro (define_dependency_libs TARGET)
    # ThirdParty/SDL external dependency
    if (${TARGET} MATCHES SDL|Urho3D)
        if (WIN32)
            list (APPEND LINK_LIBS_ONLY user32 gdi32 winmm imm32 ole32 oleaut32 version uuid)
        elseif (APPLE)
            list (APPEND LINK_LIBS_ONLY dl pthread)
        elseif (ANDROID)
            list (APPEND LINK_LIBS_ONLY dl log android)
        else ()
            # Linux
            list (APPEND LINK_LIBS_ONLY dl pthread rt)
            if (RASPI)
                list (APPEND ABSOLUTE_PATH_LIBS ${BCM_VC_LIBRARIES})
            endif ()
        endif ()
    endif ()

    # ThirdParty/kNet & ThirdParty/Civetweb external dependency
    if (${TARGET} MATCHES Civetweb|kNet|Urho3D)
        if (WIN32)
            list (APPEND LINK_LIBS_ONLY ws2_32)
        elseif (NOT ANDROID)
            list (APPEND LINK_LIBS_ONLY pthread)
        endif ()
    endif ()

    # Engine/LuaJIT external dependency
    if (URHO3D_LUAJIT AND ${TARGET} MATCHES LuaJIT|Urho3D)
        if (NOT WIN32)
            list (APPEND LINK_LIBS_ONLY dl m)
        endif ()
    endif ()

    # Engine external dependency
    if (${TARGET} STREQUAL Urho3D)
        # Core
        if (WIN32)
            list (APPEND LINK_LIBS_ONLY winmm)
            if (URHO3D_MINIDUMPS)
                list (APPEND LINK_LIBS_ONLY dbghelp)
            endif ()
        elseif (NOT ANDROID)
            list (APPEND LINK_LIBS_ONLY pthread)
        endif ()

        # Graphics
        if (URHO3D_OPENGL)
            if (WIN32)
                list (APPEND LINK_LIBS_ONLY opengl32)
            elseif (ANDROID)
                list (APPEND LINK_LIBS_ONLY GLESv1_CM GLESv2)
            elseif (NOT APPLE AND NOT RASPI)
                list (APPEND LINK_LIBS_ONLY GL)
            endif ()
        else ()
            if (DIRECT3D_FOUND)
                list (APPEND ABSOLUTE_PATH_LIBS ${DIRECT3D_LIBRARIES} ${DIRECT3D_COMPILER_LIBRARIES})
            else ()
                # If SDK not found, assume the libraries are found from default directories
                list (APPEND LINK_LIBS_ONLY d3d9 d3dcompiler)
            endif ()
        endif ()

        # This variable value can either be 'Urho3D' target or an absolute path to an actual static/shared Urho3D library or empty (if we are building the library itself)
        # The former would cause CMake not only to link against the Urho3D library but also to add a dependency to Urho3D target
        if (URHO3D_LIBRARIES)
            if (WIN32 AND URHO3D_LIBRARIES_DBG AND URHO3D_LIBRARIES_REL AND TARGET ${TARGET_NAME})
                # Special handling when both debug and release libraries are being found
                target_link_libraries (${TARGET_NAME} debug ${URHO3D_LIBRARIES_DBG} optimized ${URHO3D_LIBRARIES_REL})
            else ()
                list (APPEND ABSOLUTE_PATH_LIBS ${URHO3D_LIBRARIES})
            endif ()
        endif ()
    endif ()

    # LuaJIT specific - extra linker flags for linking against LuaJIT (adapted from LuaJIT's original Makefile)
    if (URHO3D_LUAJIT AND ${TARGET} MATCHES Urho3D)
        # 64-bit Mac OS X
        if (URHO3D_64BIT AND APPLE AND NOT IOS)
            set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pagezero_size 10000 -image_base 100000000")
        endif ()
        # GCC-specific
        if (NOT WIN32 AND NOT APPLE AND NOT ANDROID)
            set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-E")
        endif ()
    endif ()
endmacro ()

# Macro for sorting and removing duplicate values
macro (remove_duplicate LIST_NAME)
    if (${LIST_NAME})
        list (SORT ${LIST_NAME})
        list (REMOVE_DUPLICATES ${LIST_NAME})
    endif ()
endmacro ()

# Macro for setting a list from another with option to sort and remove duplicate values
macro (set_list TO_LIST FROM_LIST)
    set (${TO_LIST} ${${FROM_LIST}})
    if (${ARGN} STREQUAL REMOVE_DUPLICATE)
        remove_duplicate (${TO_LIST})
    endif ()
endmacro ()

# Macro for defining source files with optional arguments as follows:
#  GROUP <value> - Group source files into a sub-group folder in VS and Xcode (only works in curent scope context)
#  GLOB_CPP_PATTERNS <list> - Use the provided globbing patterns for CPP_FILES instead of the default *.cpp
#  GLOB_H_PATTERNS <list> - Use the provided globbing patterns for H_FILES instead of the default *.h
#  EXTRA_CPP_FILES <list> - Include the provided list of files into CPP_FILES result
#  EXTRA_H_FILES <list> - Include the provided list of files into H_FILES result
#  PCH - Enable precompiled header on the defined source files
#  PARENT_SCOPE - Glob source files in current directory but set the result in parent-scope's variable ${DIR}_CPP_FILES and ${DIR}_H_FILES instead
macro (define_source_files)
    # Parse extra arguments
    cmake_parse_arguments (ARG "PCH;PARENT_SCOPE" "GROUP" "EXTRA_CPP_FILES;EXTRA_H_FILES;GLOB_CPP_PATTERNS;GLOB_H_PATTERNS" ${ARGN})

    # Source files are defined by globbing source files in current source directory and also by including the extra source files if provided
    if (NOT ARG_GLOB_CPP_PATTERNS)
        set (ARG_GLOB_CPP_PATTERNS *.cpp)    # Default glob pattern
    endif ()
    if (NOT ARG_GLOB_H_PATTERNS)
        set (ARG_GLOB_H_PATTERNS *.h)
    endif ()
    file (GLOB CPP_FILES ${ARG_GLOB_CPP_PATTERNS})
    file (GLOB H_FILES ${ARG_GLOB_H_PATTERNS})
    list (APPEND CPP_FILES ${ARG_EXTRA_CPP_FILES})
    list (APPEND H_FILES ${ARG_EXTRA_H_FILES})
    set (SOURCE_FILES ${CPP_FILES} ${H_FILES})
    
    # Optionally enable PCH
    if (ARG_PCH)
        enable_pch ()
    endif ()
    
    # Optionally accumulate source files at parent scope
    if (ARG_PARENT_SCOPE)
        get_filename_component (DIR_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)
        set (${DIR_NAME}_CPP_FILES ${CPP_FILES} PARENT_SCOPE)
        set (${DIR_NAME}_H_FILES ${H_FILES} PARENT_SCOPE)
    # Optionally put source files into further sub-group (only works for current scope due to CMake limitation)
    elseif (ARG_GROUP)
        source_group ("Source Files\\${ARG_GROUP}" FILES ${CPP_FILES})
        source_group ("Header Files\\${ARG_GROUP}" FILES ${H_FILES})
    endif ()
endmacro ()

# Macro for preparing an amalgamated build
macro (prepare_amalgamated_build)
    if (URHO3D_AMALG)
        if (MSVC)
            set (AMALG_SINGLE_TARGET 1)
        endif ()
        foreach (SOURCE ${SOURCE_FILES})
            get_filename_component (EXT ${SOURCE} EXT)
            if (EXT MATCHES \\.c.*$|\\.mm?$)
                if (AMALG_EXCLUDES AND SOURCE MATCHES "${AMALG_EXCLUDES}")
                    set (EXCLUDED 1)
                else ()
                    foreach (LIST EXTS${AMALG_SINGLE_TARGET} AMALG_EXTS${AMALG_SINGLE_TARGET})
                        list (APPEND ${LIST} ${EXT})
                        list (REMOVE_DUPLICATES ${LIST})
                    endforeach ()
                    set_source_files_properties (${SOURCE} PROPERTIES HEADER_FILE_ONLY TRUE)
                    get_source_file_property (SOURCE ${SOURCE} LOCATION)
                    list (APPEND AMALG_SOURCES${AMALG_SINGLE_TARGET}${EXT} ${SOURCE})
                endif ()
            endif ()
        endforeach ()
        if (NOT AMALG_SINGLE_TARGET)
            get_directory_property (COMPILE_DEFINITIONS COMPILE_DEFINITIONS)
            list (APPEND AMALG_COMPILE_DEFINITIONS ${COMPILE_DEFINITIONS})
            list (REMOVE_DUPLICATES AMALG_COMPILE_DEFINITIONS)
            if (NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
                set (AMALG_EXTS ${AMALG_EXTS} PARENT_SCOPE)
                foreach (EXT ${EXTS})
                    set (AMALG_SOURCES${EXT} ${AMALG_SOURCES${EXT}} PARENT_SCOPE)
                endforeach ()
                set (AMALG_COMPILE_DEFINITIONS ${AMALG_COMPILE_DEFINITIONS} PARENT_SCOPE)
            endif ()
        endif ()
        if (APPLE AND NOT EXCLUDED)
            # Apple librarian tool does not like being called with empty list of archive members (i.e. when they are all being optimized out by amalgamated build)
            add_custom_command (OUTPUT dummy.c COMMAND touch dummy.c COMMENT "")
            list (APPEND SOURCE_FILES dummy.c)
        endif ()
        if ("${ARGN}" STREQUAL FINALIZED OR AMALG_FINAL_TARGET OR AMALG_SINGLE_TARGET)
            foreach (EXT ${AMALG_EXTS${AMALG_SINGLE_TARGET}})
                finalize_amalgamated_build ()
            endforeach ()
            if (NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
                set (AMALG_EXTS${AMALG_SINGLE_TARGET} "" PARENT_SCOPE)
                set (AMALG_COMPILE_DEFINITIONS${AMALG_SINGLE_TARGET} "" PARENT_SCOPE)
            endif ()
        endif ()
    endif ()
endmacro ()

# Macro for finalizing an amalgamated build
macro (finalize_amalgamated_build)
    list (LENGTH AMALG_SOURCES${AMALG_SINGLE_TARGET}${EXT} LENGTH)
    if (NOT LENGTH LESS URHO3D_AMALG)
        math (EXPR UNIT_LENGTH "${LENGTH} / ${URHO3D_AMALG}")
    else ()
        set (UNIT_LENGTH 1)
    endif ()
    set (START_INDEX 0)
    foreach (UNIT RANGE 1 ${URHO3D_AMALG})
        if (NOT START_INDEX LESS LENGTH)
            break ()
        endif ()
        if (UNIT EQUAL ${URHO3D_AMALG})
            math (EXPR END_INDEX "${LENGTH} - 1")
        else ()
            math (EXPR END_INDEX "${START_INDEX} + ${UNIT_LENGTH} - 1")
        endif ()
        unset (UNIT_SOURCES)
        foreach (INDEX RANGE ${START_INDEX} ${END_INDEX})
            list (GET AMALG_SOURCES${AMALG_SINGLE_TARGET}${EXT} ${INDEX} SOURCE)
            list (APPEND UNIT_SOURCES ${SOURCE})
        endforeach ()
        math (EXPR START_INDEX "${END_INDEX} + 1")
        string (REGEX REPLACE ";([^;]+)" "#include \"\\1\"\n" FILE_CONTENT "// Please DO NOT modify this auto-generated file!\n\n;${UNIT_SOURCES}")
        set (FILENAME ${CMAKE_CURRENT_BINARY_DIR}/generated/AMALG_${UNIT}${EXT})
        file (WRITE ${FILENAME}.tmp ${FILE_CONTENT})
        execute_process (COMMAND ${CMAKE_COMMAND} -E copy_if_different ${FILENAME}.tmp ${FILENAME})
        file (REMOVE ${FILENAME}.tmp)
        set_source_files_properties (${FILENAME} PROPERTIES COMPILE_DEFINITIONS "${AMALG_COMPILE_DEFINITIONS}" GENERATED TRUE)
        list (APPEND SOURCE_FILES ${FILENAME})
        if (MSVC)
            get_source_file_property (COMPILE_FLAGS ${SOURCE} COMPILE_FLAGS)
            if (COMPILE_FLAGS MATCHES "/Yu(.+)")
                get_source_file_property(LOCATION ${CMAKE_MATCH_1} LOCATION)
                get_filename_component (PATH ${LOCATION} PATH)
                include_directories (${PATH})
            endif ()
        endif ()
    endforeach ()
    if (NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
        set (AMALG_SOURCES${AMALG_SINGLE_TARGET}${EXT} "" PARENT_SCOPE)
    endif ()
endmacro ()
