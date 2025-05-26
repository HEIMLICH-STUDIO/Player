cmake_minimum_required(VERSION 3.16)

# 프로젝트 버전 정의
set(PROJECT_VERSION_MAJOR 0)
set(PROJECT_VERSION_MINOR 0)
set(PROJECT_VERSION_PATCH 2)
set(PROJECT_VERSION_BUILD 1)

# Git 정보 가져오기 (선택사항)
find_package(Git QUIET)
if(GIT_FOUND)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_TAG
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
endif()

# 버전 문자열 생성
if(GIT_TAG)
    set(VERSION_STRING "${GIT_TAG}")
    if(GIT_COMMIT_HASH)
        set(VERSION_STRING "${VERSION_STRING}-${GIT_COMMIT_HASH}")
    endif()
else()
    set(VERSION_STRING "v${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")
    if(GIT_COMMIT_HASH)
        set(VERSION_STRING "${VERSION_STRING}-${GIT_COMMIT_HASH}")
    endif()
endif()

# 빌드 날짜 추가
string(TIMESTAMP BUILD_DATE "%Y-%m-%d")
set(VERSION_STRING "${VERSION_STRING} (${BUILD_DATE})")

message(STATUS "Building Player by HEIMLICH® version: ${VERSION_STRING}")

project(Player-by-HEIMLICH VERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH})

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

find_package(Qt6 COMPONENTS Core Quick Gui OpenGL QuickControls2 Widgets REQUIRED)

# Check for FFmpeg support (preferred)
set(FFMPEG_FOUND FALSE)

# Try to find FFmpeg using pkg-config first
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(FFMPEG QUIET libavformat libavcodec libavutil libswscale)
    if(FFMPEG_FOUND)
        message(STATUS "Found FFmpeg via pkg-config")
        message(STATUS "FFmpeg include dirs: ${FFMPEG_INCLUDE_DIRS}")
        message(STATUS "FFmpeg libraries: ${FFMPEG_LIBRARIES}")
    endif()
endif()

# If pkg-config didn't work, try to find FFmpeg manually
if(NOT FFMPEG_FOUND)
    # Look for FFmpeg in common locations
    set(FFMPEG_ROOT_PATHS
        "${CMAKE_SOURCE_DIR}/external/ffmpeg"
        "C:/msys64/mingw64"
        "C:/ffmpeg"
        "/usr/local"
        "/usr"
        "/opt/local"
    )
    
    foreach(FFMPEG_ROOT ${FFMPEG_ROOT_PATHS})
        if(EXISTS "${FFMPEG_ROOT}/include/libavformat/avformat.h" AND
           EXISTS "${FFMPEG_ROOT}/include/libavcodec/avcodec.h")
            set(FFMPEG_FOUND TRUE)
            set(FFMPEG_INCLUDE_DIRS "${FFMPEG_ROOT}/include")
            
            # Find libraries
            if(WIN32)
                set(FFMPEG_LIBRARIES
                    "${FFMPEG_ROOT}/lib/libavformat.dll.a"
                    "${FFMPEG_ROOT}/lib/libavcodec.dll.a"
                    "${FFMPEG_ROOT}/lib/libavutil.dll.a"
                    "${FFMPEG_ROOT}/lib/libswscale.dll.a"
                )
                # Find DLLs for runtime
                set(FFMPEG_DLLS
                    "${FFMPEG_ROOT}/bin/avformat-61.dll"
                    "${FFMPEG_ROOT}/bin/avcodec-61.dll"
                    "${FFMPEG_ROOT}/bin/avutil-59.dll"
                    "${FFMPEG_ROOT}/bin/swscale-8.dll"
                )
            else()
                set(FFMPEG_LIBRARIES
                    "${FFMPEG_ROOT}/lib/libavformat.so"
                    "${FFMPEG_ROOT}/lib/libavcodec.so"
                    "${FFMPEG_ROOT}/lib/libavutil.so"
                    "${FFMPEG_ROOT}/lib/libswscale.so"
                )
            endif()
            
            message(STATUS "Found FFmpeg at: ${FFMPEG_ROOT}")
            break()
        endif()
    endforeach()
endif()

# Check if MPV is available for the current platform (fallback)
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

# Determine which backend to use
if(FFMPEG_FOUND)
    message(STATUS "Building with FFmpeg support (preferred)")
    set(USE_FFMPEG TRUE)
    set(USE_MPV FALSE)
elseif(MPV_FOUND)
    message(STATUS "Building with MPV support (fallback)")
    message(STATUS "MPV include directory: ${MPV_INCLUDE_DIR}")
    message(STATUS "MPV library: ${MPV_LIBRARY}")
    set(USE_FFMPEG FALSE)
    set(USE_MPV TRUE)
else()
    message(WARNING "Neither FFmpeg nor MPV found. Building basic version without video backend.")
    set(USE_FFMPEG FALSE)
    set(USE_MPV FALSE)
endif()

# Set project sources based on available backend
if(USE_FFMPEG)
    message(STATUS "Building Player by HEIMLICH® with FFmpeg support")
    if(WIN32)
        # 아이콘 파일을 빌드 디렉토리로 복사
        configure_file(
            "${CMAKE_SOURCE_DIR}/assets/Images/icon_win.ico"
            "${CMAKE_BINARY_DIR}/icon_win.ico"
            COPYONLY
        )
        
        # 추가 아이콘 위치에도 복사
        configure_file(
            "${CMAKE_SOURCE_DIR}/assets/Images/icon_win.ico"
            "${CMAKE_SOURCE_DIR}/icon_win.ico"
            COPYONLY
        )
        
        # Windows 리소스 파일 템플릿 생성
        configure_file(
            "${CMAKE_SOURCE_DIR}/resources.rc"
            "${CMAKE_BINARY_DIR}/resources.rc"
            @ONLY
        )
        
        # 실행파일 생성 (리소스 파일 포함)
        add_executable(${PROJECT_NAME} WIN32
            src/main.cpp
            src/core/ffmpegobject.cpp
            src/core/ffmpegobject.h
            qml.qrc
            "${CMAKE_BINARY_DIR}/resources.rc"
        )
    else()
        add_executable(${PROJECT_NAME}
            src/main.cpp
            src/core/ffmpegobject.cpp
            src/core/ffmpegobject.h
            qml.qrc
        )
    endif()
    
    # Define HAVE_FFMPEG for conditional compilation
    add_compile_definitions(HAVE_FFMPEG)
elseif(USE_MPV)
    message(STATUS "Building Player by HEIMLICH® with MPV support")
    if(WIN32)
        # 아이콘 파일을 빌드 디렉토리로 복사
        configure_file(
            "${CMAKE_SOURCE_DIR}/assets/Images/icon_win.ico"
            "${CMAKE_BINARY_DIR}/icon_win.ico"
            COPYONLY
        )
        
        # 추가 아이콘 위치에도 복사
        configure_file(
            "${CMAKE_SOURCE_DIR}/assets/Images/icon_win.ico"
            "${CMAKE_SOURCE_DIR}/icon_win.ico"
            COPYONLY
        )
        
        # Windows 리소스 파일 템플릿 생성
        configure_file(
            "${CMAKE_SOURCE_DIR}/resources.rc"
            "${CMAKE_BINARY_DIR}/resources.rc"
            @ONLY
        )
        
        # 실행파일 생성 (리소스 파일 포함)
        add_executable(${PROJECT_NAME} WIN32
            src/main.cpp
            src/mpvobject.cpp
            src/mpvobject.h
            src/timelinesync.cpp
            src/timelinesync.h
            qml.qrc
            "${CMAKE_BINARY_DIR}/resources.rc"
        )
    else()
        add_executable(${PROJECT_NAME}
            src/main.cpp
            src/mpvobject.cpp
            src/mpvobject.h
            src/timelinesync.cpp
            src/timelinesync.h
            qml.qrc
        )
    endif()
    
    # Define HAVE_MPV for conditional compilation
    add_compile_definitions(HAVE_MPV)
else()
    message(STATUS "Building Player by HEIMLICH® (Basic Version without MPV)")
    if(WIN32)
        # 아이콘 파일을 빌드 디렉토리로 복사
        configure_file(
            "${CMAKE_SOURCE_DIR}/assets/Images/icon_win.ico"
            "${CMAKE_BINARY_DIR}/icon_win.ico"
            COPYONLY
        )
        
        # 추가 아이콘 위치에도 복사
        configure_file(
            "${CMAKE_SOURCE_DIR}/assets/Images/icon_win.ico"
            "${CMAKE_SOURCE_DIR}/icon_win.ico"
            COPYONLY
        )
        
        # Windows 리소스 파일 템플릿 생성
        configure_file(
            "${CMAKE_SOURCE_DIR}/resources.rc"
            "${CMAKE_BINARY_DIR}/resources.rc"
            @ONLY
        )
        
        # 실행파일 생성 (리소스 파일 포함)
        add_executable(${PROJECT_NAME} WIN32
            src/main.cpp
            qml.qrc
            "${CMAKE_BINARY_DIR}/resources.rc"
        )
    else()
        add_executable(${PROJECT_NAME}
            src/main.cpp
            qml.qrc
        )
    endif()
endif()

# Link libraries
if(USE_FFMPEG)
    target_include_directories(${PROJECT_NAME} PRIVATE ${FFMPEG_INCLUDE_DIRS})
    target_link_libraries(${PROJECT_NAME} PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Gui
        Qt6::OpenGL
        Qt6::QuickControls2
        Qt6::Widgets
        ${FFMPEG_LIBRARIES}
    )
elseif(USE_MPV)
    target_include_directories(${PROJECT_NAME} PRIVATE ${MPV_INCLUDE_DIR})
    target_link_libraries(${PROJECT_NAME} PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Gui
        Qt6::OpenGL
        Qt6::QuickControls2
        Qt6::Widgets
        ${MPV_LIBRARY}
    )
    
    # Post-build command to copy FFmpeg DLLs (Windows)
    if(WIN32 AND FFMPEG_DLLS)
        foreach(DLL ${FFMPEG_DLLS})
            if(EXISTS "${DLL}")
                add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${DLL}"
                    $<TARGET_FILE_DIR:${PROJECT_NAME}>
                )
            endif()
        endforeach()
    endif()
    
    # Post-build command to copy MPV DLL (Windows and macOS) - fallback
    if(WIN32 AND EXISTS "${MPV_DLL}")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${MPV_DLL}"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        )
        
        # Copy assets folder to build directory for installer
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/assets"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/assets"
            COMMENT "Copying assets folder to build directory"
        )
        
        # Copy QML folder to build directory for installer
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/qml"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/qml"
            COMMENT "Copying QML folder to build directory"
        )
    elseif(APPLE AND EXISTS "${MPV_DLL}")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${MPV_DLL}"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        )
        
        # Copy assets folder to build directory for installer (macOS)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/assets"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/assets"
            COMMENT "Copying assets folder to build directory"
        )
        
        # Copy QML folder to build directory for installer (macOS)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/qml"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/qml"
            COMMENT "Copying QML folder to build directory"
        )
        
        # Set macOS bundle properties if needed
        set_target_properties(${PROJECT_NAME} PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/macos/Info.plist
            MACOSX_BUNDLE_ICON_FILE icon_mac.icns
        )
        
        # Copy icon file to Resources directory in bundle
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
                ${CMAKE_SOURCE_DIR}/assets/Images/icon_mac.icns
                $<TARGET_BUNDLE_CONTENT_DIR:${PROJECT_NAME}>/Resources/icon_mac.icns
            COMMENT "Copying macOS icon to bundle Resources"
        )
    else()
        # Copy assets and QML folders even without MPV DLL (for other platforms)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/assets"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/assets"
            COMMENT "Copying assets folder to build directory"
        )
        
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/qml"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/qml"
            COMMENT "Copying QML folder to build directory"
        )
    endif()
else()
    target_link_libraries(${PROJECT_NAME} PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Gui
        Qt6::OpenGL
        Qt6::QuickControls2
        Qt6::Widgets
    )
    
    # Copy assets and QML folders to build directory even without MPV
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_SOURCE_DIR}/assets"
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/assets"
        COMMENT "Copying assets folder to build directory"
    )
    
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_SOURCE_DIR}/qml"
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/qml"
        COMMENT "Copying QML folder to build directory"
    )
endif()

target_compile_definitions(${PROJECT_NAME} PRIVATE
    $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
    VERSION_STRING="${VERSION_STRING}"
    PROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
    PROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
    PROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH}
)

# 동적 인스톨러 생성 시스템
# installer.nsi.in 템플릿에서 실제 installer.nsi 생성
configure_file(
    "${CMAKE_SOURCE_DIR}/installer.nsi.in"
    "${CMAKE_SOURCE_DIR}/installer.nsi"
    @ONLY
)

# 인스톨러 생성을 위한 커스텀 타겟
if(WIN32)
    # NSIS 경로 찾기
    find_program(NSIS_MAKENSIS
        NAMES makensis
        PATHS 
            "C:/Program Files (x86)/NSIS"
            "C:/Program Files/NSIS"
            "$ENV{PROGRAMFILES}/NSIS"
        DOC "NSIS makensis executable"
    )
    
    if(NSIS_MAKENSIS)
        message(STATUS "Found NSIS: ${NSIS_MAKENSIS}")
        
        # 인스톨러 생성 타겟
        add_custom_target(installer
            COMMAND ${NSIS_MAKENSIS} /V3 "${CMAKE_SOURCE_DIR}/installer.nsi"
            DEPENDS ${PROJECT_NAME}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            COMMENT "Creating installer with version ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}"
        )
        
        message(STATUS "Installer target created. Use 'cmake --build . --target installer' to build installer")
    else()
        message(WARNING "NSIS not found. Installer target will not be available.")
        message(STATUS "Install NSIS from: https://nsis.sourceforge.io/")
    endif()
endif() 