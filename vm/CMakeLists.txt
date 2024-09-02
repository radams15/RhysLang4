cmake_minimum_required(VERSION 3.20)

project(VM C)

include(FetchContent)

FetchContent_Declare(
        rhys
        GIT_REPOSITORY https://github.com/radams15/librhys.git
        GIT_TAG        v0.1.0
)
FetchContent_MakeAvailable(rhys)

add_executable(vm main.c
        defs.h)

target_link_libraries(vm PRIVATE rhys)