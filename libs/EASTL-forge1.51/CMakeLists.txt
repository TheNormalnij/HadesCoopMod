project(EASTL CXX)
add_library(EASTL STATIC)
target_compile_features(EASTL PUBLIC cxx_std_17)

file(GLOB EASTL_BOUNUS bonus/*)
file(GLOB EASTL_EAAssert EAAssert/*)
file(GLOB_RECURSE EASTL_EABASE EABase/*.h)
file(GLOB EASTL_EASTDC EAStdC/*)
file(GLOB EASTL_INTERNAL internal/*)
file(GLOB EASTL_MAIN_HEADERS *.h)
file(GLOB EASTL_MAIN_SOURCES *.cpp)

# Disable eastl debugging to save binary compatibility with the game.
add_definitions( -DEASTL_DEBUG=0 )

add_definitions(-DEASTL_CUSTOM_FLOAT_CONSTANTS_REQUIRED)
add_definitions(-D_CHAR16T)
add_definitions(-D_CRT_SECURE_NO_WARNINGS)
add_definitions(-D_SCL_SECURE_NO_WARNINGS)
add_definitions(-DEASTL_OPENSOURCE=1)

target_sources(
    EASTL
    PUBLIC
    "forge/IMemory.h"
    "forge/coreconfig.h"
    "vector.h"
    "allocator_forge.cpp"
)

target_include_directories(EASTL INTERFACE ./)
