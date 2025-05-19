cmake_minimum_required(VERSION 3.16)
project(HYPER-PLAYER VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# For MSVC compilers, add /Zc:__cplusplus option to fix Qt error
if(MSVC)
    add_compile_options(/Zc:__cplusplus)
endif()

# Cross-platform support
if(WIN32)
    set(PLATFORM_NAME "windows")
elseif(APPLE)
    set(PLATFORM_NAME "macos")
elseif(ANDROID)
    set(PLATFORM_NAME "android")
else()
    set(PLATFORM_NAME "linux")
endif()

message(STATUS "Building for platform: ${PLATFORM_NAME}")

find_package(Qt6 COMPONENTS Core Quick Gui OpenGL QuickControls2 REQUIRED)

# Check if MPV is available for the current platform
set(MPV_FOUND FALSE)
set(MPV_ROOT "${CMAKE_SOURCE_DIR}/external/libs/${PLATFORM_NAME}")

# Platform-specific MPV settings
if(WIN32)
    if(EXISTS "${MPV_ROOT}/include/client.h" AND 
       EXISTS "${MPV_ROOT}/bin/libmpv-2.dll")
        set(MPV_FOUND TRUE)
        set(MPV_INCLUDE_DIR "${MPV_ROOT}/include")
        set(MPV_LIBRARY "${MPV_ROOT}/lib/libmpv.dll.a")
        set(MPV_DLL "${MPV_ROOT}/bin/libmpv-2.dll")
    elseif(EXISTS "${CMAKE_SOURCE_DIR}/external/mpv-dev/include/client.h" AND 
          EXISTS "${CMAKE_SOURCE_DIR}/external/mpv-dev/bin/libmpv-2.dll")
        # Fallback to previous path if exists
        set(MPV_FOUND TRUE)
        set(MPV_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/external/mpv-dev/include")
        set(MPV_LIBRARY "${CMAKE_SOURCE_DIR}/external/mpv-dev/lib/libmpv.dll.a")
        set(MPV_DLL "${CMAKE_SOURCE_DIR}/external/mpv-dev/bin/libmpv-2.dll")
        message(STATUS "Using fallback MPV path")
    endif()
elseif(APPLE)
    if(EXISTS "${MPV_ROOT}/include/mpv/client.h")
        set(MPV_FOUND TRUE)
        set(MPV_INCLUDE_DIR "${MPV_ROOT}/include")
        set(MPV_LIBRARY "${MPV_ROOT}/lib/libmpv.dylib")
        set(MPV_DLL "${MPV_ROOT}/lib/libmpv.dylib")
    endif()
elseif(ANDROID)
    if(EXISTS "${MPV_ROOT}/include/mpv/client.h")
        set(MPV_FOUND TRUE)
        set(MPV_INCLUDE_DIR "${MPV_ROOT}/include")
        set(MPV_LIBRARY "${MPV_ROOT}/lib/libmpv.so")
    endif()
else() # Linux
    if(EXISTS "${MPV_ROOT}/include/mpv/client.h")
        set(MPV_FOUND TRUE)
        set(MPV_INCLUDE_DIR "${MPV_ROOT}/include")
        set(MPV_LIBRARY "${MPV_ROOT}/lib/libmpv.so")
    else()
        # Try to find system-installed mpv on Linux
        find_package(PkgConfig REQUIRED)
        pkg_check_modules(MPV IMPORTED_TARGET mpv)
        if(MPV_FOUND)
            set(MPV_INCLUDE_DIR ${MPV_INCLUDE_DIRS})
            set(MPV_LIBRARY ${MPV_LIBRARIES})
            message(STATUS "Found system MPV: ${MPV_LIBRARY}")
        endif()
    endif()
endif()

if(MPV_FOUND)
    message(STATUS "Found MPV libraries for ${PLATFORM_NAME}")
    message(STATUS "MPV include directory: ${MPV_INCLUDE_DIR}")
    message(STATUS "MPV library: ${MPV_LIBRARY}")
else()
    message(WARNING "MPV not found for platform ${PLATFORM_NAME}. Building without MPV support.")
endif()

# Set project sources based on MPV availability
if(MPV_FOUND)
    message(STATUS "Building HYPER-PLAYER with MPV support")
    set(PROJECT_SOURCES
        src/main.cpp
        src/mpvobject.cpp
        src/mpvobject.h
        qml.qrc
    )
    
    # Define MPV_AVAILABLE for conditional compilation
    add_compile_definitions(MPV_AVAILABLE)
else()
    message(STATUS "Building HYPER-PLAYER (Basic Version without MPV)")
    set(PROJECT_SOURCES
        src/main.cpp
        qml.qrc
    )
endif()

qt_add_executable(${PROJECT_NAME} ${PROJECT_SOURCES})

# Link libraries
if(MPV_FOUND)
    target_include_directories(${PROJECT_NAME} PRIVATE ${MPV_INCLUDE_DIR})
    target_link_libraries(${PROJECT_NAME} PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Gui
        Qt6::OpenGL
        Qt6::QuickControls2
        ${MPV_LIBRARY}
    )
    
    # Post-build command to copy DLL (Windows and macOS)
    if(WIN32 AND EXISTS "${MPV_DLL}")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${MPV_DLL}"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        )
    elseif(APPLE AND EXISTS "${MPV_DLL}")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${MPV_DLL}"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        )
        # Set macOS bundle properties if needed
        set_target_properties(${PROJECT_NAME} PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/macos/Info.plist
        )
    endif()
else()
    target_link_libraries(${PROJECT_NAME} PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Gui
        Qt6::OpenGL
        Qt6::QuickControls2
    )
endif()

target_compile_definitions(${PROJECT_NAME} PRIVATE
    $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
) 