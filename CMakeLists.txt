cmake_minimum_required(VERSION 3.20)

project(Hades2Coop VERSION 1.2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)

if ( MSVC )
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_SOURCE_DIR}/bin)

    set(COMPILE_OPTIONS
        $<$<CONFIG:Release>:/Zi /W3 /O2 /MP>
        $<$<CONFIG:Debug>:/Zi /W3 /Od /GF /Gm- /RTCc /RTC1 /MP>
    )

    set(LINK_OPTIONS
        /SUBSYSTEM:WINDOWS /DYNAMICBASE:NO
        $<$<CONFIG:Release>:/INCREMENTAL:NO /OPT:REF /OPT:ICF>
        $<$<CONFIG:Debug>:/INCREMENTAL /DEBUG>
    )

endif()

add_subdirectory(libs/EASTL-forge1.51)
add_subdirectory(libs/lua-5.2.2)

add_subdirectory(game)

