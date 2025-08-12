cmake_minimum_required(VERSION 3.20)
set(CMAKE_EXPORT_COMPILE_COMMANDS true)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/cmake/toolchain.cmake)

project(app)

add_executable(${PROJECT_NAME})
target_link_libraries(${PROJECT_NAME} PRIVATE)
target_include_directories(${PROJECT_NAME} PRIVATE inc)
target_sources(${PROJECT_NAME} PRIVATE src/main.c)
target_link_options(${PROJECT_NAME} PRIVATE)
