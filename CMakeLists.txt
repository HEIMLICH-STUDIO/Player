cmake_minimum_required(VERSION 3.16)

# 프로젝트 버전 정의
set(PROJECT_VERSION_MAJOR 0)
set(PROJECT_VERSION_MINOR 0)
set(PROJECT_VERSION_PATCH 0)
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

find_package(Qt6 COMPONENTS Core Quick Gui OpenGL OpenGLWidgets QuickControls2 Widgets REQUIRED)

# FFmpeg 설정
find_package(PkgConfig)
if(PkgConfig_FOUND)
    message(STATUS "PkgConfig found, using pkg-config to find FFmpeg")
    pkg_check_modules(FFMPEG REQUIRED 
        libavformat>=58.0.0
        libavcodec>=58.0.0 
        libavutil>=56.0.0
        libswscale>=5.0.0
        libswresample>=3.0.0
    )
else()
    message(STATUS "PkgConfig not found, using FindPkgConfig alternative for Windows")
    # Windows에서 vcpkg 또는 직접 설치된 FFmpeg 찾기
    find_path(FFMPEG_INCLUDE_DIR libavformat/avformat.h
        HINTS
            ${CMAKE_PREFIX_PATH}/include
            C:/vcpkg/installed/x64-windows/include
            C:/vcpkg/installed/x64-mingw-dynamic/include
            C:/msys64/mingw64/include
        PATH_SUFFIXES ffmpeg
    )
    
    find_library(FFMPEG_avformat_LIBRARY avformat
        HINTS
            ${CMAKE_PREFIX_PATH}/lib
            C:/vcpkg/installed/x64-windows/lib
            C:/vcpkg/installed/x64-mingw-dynamic/lib
            C:/msys64/mingw64/lib
    )
    
    find_library(FFMPEG_avcodec_LIBRARY avcodec
        HINTS
            ${CMAKE_PREFIX_PATH}/lib
            C:/vcpkg/installed/x64-windows/lib
            C:/vcpkg/installed/x64-mingw-dynamic/lib
            C:/msys64/mingw64/lib
    )
    
    find_library(FFMPEG_avutil_LIBRARY avutil
        HINTS
            ${CMAKE_PREFIX_PATH}/lib
            C:/vcpkg/installed/x64-windows/lib
            C:/vcpkg/installed/x64-mingw-dynamic/lib
            C:/msys64/mingw64/lib
    )
    
    find_library(FFMPEG_swscale_LIBRARY swscale
        HINTS
            ${CMAKE_PREFIX_PATH}/lib
            C:/vcpkg/installed/x64-windows/lib
            C:/vcpkg/installed/x64-mingw-dynamic/lib
            C:/msys64/mingw64/lib
    )
    
    find_library(FFMPEG_swresample_LIBRARY swresample
        HINTS
            ${CMAKE_PREFIX_PATH}/lib
            C:/vcpkg/installed/x64-windows/lib
            C:/vcpkg/installed/x64-mingw-dynamic/lib
            C:/msys64/mingw64/lib
    )
    
    if(FFMPEG_INCLUDE_DIR AND FFMPEG_avformat_LIBRARY AND FFMPEG_avcodec_LIBRARY 
       AND FFMPEG_avutil_LIBRARY AND FFMPEG_swscale_LIBRARY AND FFMPEG_swresample_LIBRARY)
        set(FFMPEG_FOUND TRUE)
        set(FFMPEG_INCLUDE_DIRS ${FFMPEG_INCLUDE_DIR})
        set(FFMPEG_LIBRARIES 
            ${FFMPEG_avformat_LIBRARY}
            ${FFMPEG_avcodec_LIBRARY}
            ${FFMPEG_avutil_LIBRARY}
            ${FFMPEG_swscale_LIBRARY}
            ${FFMPEG_swresample_LIBRARY}
        )
        message(STATUS "Found FFmpeg libraries manually")
        message(STATUS "  Include dir: ${FFMPEG_INCLUDE_DIRS}")
        message(STATUS "  Libraries: ${FFMPEG_LIBRARIES}")
    else()
        set(FFMPEG_FOUND FALSE)
        message(STATUS "FFmpeg not found in standard locations")
        message(STATUS "  Include dir: ${FFMPEG_INCLUDE_DIR}")
        message(STATUS "  avformat: ${FFMPEG_avformat_LIBRARY}")
        message(STATUS "  avcodec: ${FFMPEG_avcodec_LIBRARY}")
        message(STATUS "  avutil: ${FFMPEG_avutil_LIBRARY}")
        message(STATUS "  swscale: ${FFMPEG_swscale_LIBRARY}")
        message(STATUS "  swresample: ${FFMPEG_swresample_LIBRARY}")
    endif()
endif()

if(FFMPEG_FOUND)
    message(STATUS "Using FFmpeg engine")
    add_compile_definitions(USE_FFMPEG_ENGINE)
else()
    message(FATAL_ERROR "FFmpeg not found. Please install FFmpeg via vcpkg, MSYS2, or manually.")
endif()

# Set project sources
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
        src/FFmpegObject.cpp
        src/core/FFmpegEngine.cpp
        src/core/VideoDecoder.cpp
        src/core/AudioDecoder.cpp
        src/rendering/VideoRenderer.cpp
        src/utils/TimecodeUtils.cpp
        src/timelinesync.cpp
        src/videoscoperenderer.cpp
        qml.qrc
        "${CMAKE_BINARY_DIR}/resources.rc"
    )
else()
    add_executable(${PROJECT_NAME}
        src/main.cpp
        src/FFmpegObject.cpp
        src/core/FFmpegEngine.cpp
        src/core/VideoDecoder.cpp
        src/core/AudioDecoder.cpp
        src/rendering/VideoRenderer.cpp
        src/utils/TimecodeUtils.cpp
        src/timelinesync.cpp
        src/videoscoperenderer.cpp
        qml.qrc
    )
endif()

# Define HAVE_FFMPEG for conditional compilation
add_compile_definitions(HAVE_FFMPEG)


# Link libraries
target_include_directories(${PROJECT_NAME} PRIVATE ${FFMPEG_INCLUDE_DIRS})
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Gui
    Qt6::OpenGL
    Qt6::OpenGLWidgets
    Qt6::QuickControls2
    Qt6::Widgets
    ${FFMPEG_LIBRARIES}
)

# Copy assets and QML folders to build directory
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