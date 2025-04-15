cmake_minimum_required(VERSION 3.20)

project(HadesCoop VERSION 1.2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)

add_subdirectory(libs/EASTL-forge1.51)
add_subdirectory(libs/lua-5.2.2)

add_subdirectory(game)

install(TARGETS HadesCoopGame
        RUNTIME
        DESTINATION ${CMAKE_SOURCE_DIR}/bin
)

install(DIRECTORY ${CMAKE_SOURCE_DIR}/game/scripts/
        DESTINATION ${CMAKE_SOURCE_DIR}/bin
)
