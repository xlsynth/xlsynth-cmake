cmake_minimum_required(VERSION 3.10)
project(Xlsynth)

set(CMAKE_CXX_STANDARD 20)

# Define the output directory for generated files
set(GENFILES_DIR ${CMAKE_BINARY_DIR}/genfiles)

# Ensure the genfiles directory exists
file(MAKE_DIRECTORY ${GENFILES_DIR})

# Set the output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Specify the submodule directory
set(XLS_REPO_DIR ${CMAKE_SOURCE_DIR}/xlsynth-repo)
set(ABSL_DIR ${CMAKE_SOURCE_DIR}/third_party/abseil)
set(GTEST_DIR ${CMAKE_SOURCE_DIR}/third_party/googletest)

# Find LLVM
find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

# Find Z3
find_package(Z3 REQUIRED)
message(STATUS "Found Z3 ${Z3_VERSION}")
message(STATUS "Using Z3Config.cmake in: ${Z3_DIR}")

# Print available Z3 targets for diagnostics
get_cmake_property(_variableNames VARIABLES)
foreach (_variableName ${_variableNames})
  if (${_variableName} MATCHES "Z3")
    message(STATUS "${_variableName}=${${_variableName}}")
  endif()
endforeach()

# Check if Z3::libz3 target exists
if (TARGET Z3::libz3)
    set(Z3_TARGET Z3::libz3)
else()
    # Fallback to just Z3 if Z3::libz3 does not exist
    set(Z3_TARGET Z3)
endif()

# Find benchmark
find_package(benchmark REQUIRED)
message(STATUS "Found benchmark ${benchmark_VERSION}")
message(STATUS "Using benchmarkConfig.cmake in: ${benchmark_DIR}")

# Find Protobuf
find_package(Protobuf REQUIRED)
message(STATUS "Found Protobuf ${Protobuf_VERSION}")
message(STATUS "Using Protobuf include directory: ${Protobuf_INCLUDE_DIR}")

# Add the Abseil submodule
add_subdirectory(${ABSL_DIR})

# Add the Google Test and Google Mock submodule
add_subdirectory(${GTEST_DIR})

# Add source files for the different components of the library
file(GLOB_RECURSE COMMON_SOURCES "${XLS_REPO_DIR}/xls/common/*.cc")
file(GLOB_RECURSE IR_SOURCES "${XLS_REPO_DIR}/xls/ir/*.cc")
file(GLOB_RECURSE SCHEDULING_SOURCES "${XLS_REPO_DIR}/xls/scheduling/*.cc")
file(GLOB_RECURSE CODEGEN_SOURCES "${XLS_REPO_DIR}/xls/codegen/*.cc")

# Add object libraries for each component
add_library(xls_common OBJECT ${COMMON_SOURCES})
add_library(xls_ir OBJECT ${IR_SOURCES})
add_library(xls_scheduling OBJECT ${SCHEDULING_SOURCES})
add_library(xls_codegen OBJECT ${CODEGEN_SOURCES})

# Custom command to generate xls/ir/op.h in the genfiles directory
add_custom_command(
    OUTPUT ${GENFILES_DIR}/op.h
    COMMAND ${CMAKE_COMMAND} -E env ${XLS_REPO_DIR}/xls/ir/render_specification_against_template ${XLS_REPO_DIR}/xls/ir/op_header.tmpl | clang-format > ${GENFILES_DIR}/op.h
    DEPENDS ${XLS_REPO_DIR}/xls/ir/op_header.tmpl ${XLS_REPO_DIR}/xls/ir/render_specification_against_template
    COMMENT "Generating and formatting op.h"
    VERBATIM
)

# Custom target to run the custom command
add_custom_target(generate_op_h ALL DEPENDS ${GENFILES_DIR}/op.h)

# Ensure the generation of op.h before building xls_ir
add_dependencies(xls_ir generate_op_h)

# Add the generated file to the list of IR sources
list(APPEND IR_SOURCES ${GENFILES_DIR}/op.h)

# Create the shared library from the object libraries
add_library(xls SHARED
    $<TARGET_OBJECTS:xls_common>
    $<TARGET_OBJECTS:xls_ir>
    $<TARGET_OBJECTS:xls_scheduling>
    $<TARGET_OBJECTS:xls_codegen>
)

# Include directories
target_include_directories(xls_common PUBLIC ${XLS_REPO_DIR} ${ABSL_DIR})
target_include_directories(xls_ir PUBLIC ${XLS_REPO_DIR} ${ABSL_DIR})
target_include_directories(xls_scheduling PUBLIC ${XLS_REPO_DIR} ${ABSL_DIR})
target_include_directories(xls_codegen PUBLIC ${XLS_REPO_DIR} ${ABSL_DIR})

# Include directories
target_include_directories(xls PUBLIC
    ${XLS_REPO_DIR}/xls
    ${LLVM_INCLUDE_DIRS}
    ${Z3_INCLUDE_DIRS}
    ${GTEST_INCLUDE_DIRS}
    ${benchmark_INCLUDE_DIRS}
    ${ABSL_DIR}
    ${ABSL_DIR}/absl
    ${GTEST_DIR}/googletest/include
    ${GTEST_DIR}/googlemock/include
    ${Protobuf_INCLUDE_DIR}
)

# Link dependencies
target_link_libraries(xls
    ${LLVM_LIBRARIES}
    ${Z3_TARGET}

    GTest::gtest
    GTest::gtest_main
    GTest::gmock
    GTest::gmock_main

    benchmark::benchmark
    absl::base
    absl::synchronization
    absl::strings
    absl::memory
    absl::flags

    protobuf::libprotobuf
)
