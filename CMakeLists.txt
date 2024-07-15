cmake_minimum_required(VERSION 3.10)
project(Xlsynth)

set(CMAKE_CXX_STANDARD 20)

set(XLS_REPO_DIR ${CMAKE_SOURCE_DIR}/xlsynth-repo)

# Add source files for the different components of the library
file(GLOB_RECURSE COMMON_SOURCES "${XLS_REPO_DIR}/xls/common/*.cc")
file(GLOB_RECURSE IR_SOURCES "${XLS_REPO_DIR}/xls/ir/*.cc")
file(GLOB_RECURSE SCHEDULING_SOURCES "${XLS_REPO_DIR}/xls/scheduling/*.cc")
file(GLOB_RECURSE CODEGEN_SOURCES "${XLS_REPO_DIR}/xls/codegen/*.cc")
file(GLOB_RECURSE DSLX_SOURCES "${XLS_REPO_DIR}/xls/dslx/*.cc")

# Function to filter out _main.cc and _test.cc files from a list of sources
function(filter_sources VAR)
    set(SRC_LIST "${${VAR}}")
    list(FILTER SRC_LIST EXCLUDE REGEX ".+_main\\.cc")
    list(FILTER SRC_LIST EXCLUDE REGEX ".+_test\\.cc")
    set(${VAR} "${SRC_LIST}" PARENT_SCOPE)
endfunction()

# Filter out files ending with _main.cc and _test.cc
filter_sources(COMMON_SOURCES)
filter_sources(IR_SOURCES)
filter_sources(SCHEDULING_SOURCES)
filter_sources(CODEGEN_SOURCES)

# Add object libraries for each component
add_library(xls_common OBJECT ${COMMON_SOURCES})
add_library(xls_ir OBJECT ${IR_SOURCES})
add_library(xls_scheduling OBJECT ${SCHEDULING_SOURCES})
add_library(xls_codegen OBJECT ${CODEGEN_SOURCES})

# Include directories
target_include_directories(xls_common PUBLIC ${XLS_REPO_DIR} ${ABSL_DIR})
target_include_directories(xls_ir PUBLIC ${XLS_REPO_DIR} ${ABSL_DIR})
target_include_directories(xls_scheduling PUBLIC ${XLS_REPO_DIR} ${ABSL_DIR})
target_include_directories(xls_codegen PUBLIC ${XLS_REPO_DIR} ${ABSL_DIR})

include(${CMAKE_SOURCE_DIR}/cmake/FindDependencies.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/GenerateFiles.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/Tests.cmake)
