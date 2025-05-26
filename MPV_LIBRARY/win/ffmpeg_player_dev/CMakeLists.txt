cmake_minimum_required(VERSION 3.16) 
project(FFmpegProResPlayer) 
 
set(CMAKE_CXX_STANDARD 17) 
 
# FFmpeg 라이브러리 찾기 
find_package(PkgConfig REQUIRED) 
pkg_check_modules(FFMPEG REQUIRED libavformat libavcodec libavutil libswscale) 
 
# 실행 파일 생성 
add_executable(prores_player main.cpp) 
 
# 라이브러리 링크 
target_link_libraries(prores_player ${FFMPEG_LIBRARIES}) 
target_include_directories(prores_player PRIVATE ${FFMPEG_INCLUDE_DIRS}) 
target_compile_options(prores_player PRIVATE ${FFMPEG_CFLAGS_OTHER}) 
