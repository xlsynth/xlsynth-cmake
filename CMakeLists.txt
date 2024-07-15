cmake_minimum_required(VERSION 3.10)
project(Xlsynth)

set(CMAKE_CXX_STANDARD 20)

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

find_package(OpenSSL REQUIRED)
message(STATUS "Found OpenSSL ${OPENSSL_VERSION}")
message(STATUS "Using OpenSSL include directory: ${OPENSSL_INCLUDE_DIR}")

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

# Add a target-specific definition for BUILD_EMBED_LABEL
target_compile_definitions(xls_common PRIVATE BUILD_EMBED_LABEL="\"your_label\"")

# Custom command to generate xls/ir/op.h in the genfiles directory
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/xls/ir/op.h
    COMMAND python3 ${XLS_REPO_DIR}/xls/ir/render_specification_against_template.py ${XLS_REPO_DIR}/xls/ir/op_header.tmpl | clang-format > ${CMAKE_CURRENT_BINARY_DIR}/xls/ir/op.h
    DEPENDS ${XLS_REPO_DIR}/xls/ir/op_header.tmpl ${XLS_REPO_DIR}/xls/ir/render_specification_against_template.py
    COMMENT "Generating and formatting op.h"
    VERBATIM
)

# Custom target to run the custom command
add_custom_target(generate_op_h ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/xls/ir/op.h)

# Ensure the generation of op.h before building xls_ir
add_dependencies(xls_ir generate_op_h)

# Add the generated file to the list of IR sources
list(APPEND IR_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/xls/ir/op.h)

# -- nodes.h

# Define paths for templates and output
set(NODES_HEADER_TEMPLATE "${XLS_REPO_DIR}/xls/ir/nodes_header.tmpl")
set(NODES_SOURCE_TEMPLATE "${XLS_REPO_DIR}/xls/ir/nodes_source.tmpl")
set(NODES_HEADER_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/xls/ir/nodes.h")
set(NODES_SOURCE_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/xls/ir/nodes.cc")

# Ensure the output directory exists
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/xls/ir")

# Custom command to generate nodes.h
add_custom_command(
    OUTPUT ${NODES_HEADER_OUTPUT}
    COMMAND python3 ${XLS_REPO_DIR}/xls/ir/render_specification_against_template.py ${NODES_HEADER_TEMPLATE}
    COMMAND clang-format -i ${NODES_HEADER_OUTPUT}
    DEPENDS ${NODES_HEADER_TEMPLATE} ${XLS_REPO_DIR}/xls/ir/render_specification_against_template.py
    COMMENT "Generating and formatting nodes.h"
    VERBATIM
)

# Custom command to generate nodes.cc
add_custom_command(
    OUTPUT ${NODES_SOURCE_OUTPUT}
    COMMAND python3 ${XLS_REPO_DIR}/xls/ir/render_specification_against_template.py ${NODES_SOURCE_TEMPLATE}
    COMMAND clang-format -i ${NODES_SOURCE_OUTPUT}
    DEPENDS ${NODES_SOURCE_TEMPLATE} ${XLS_REPO_DIR}/xls/ir/render_specification_against_template.py
    COMMENT "Generating and formatting nodes.cc"
    VERBATIM
)

# Custom target to run the custom commands
add_custom_target(generate_nodes ALL DEPENDS ${NODES_HEADER_OUTPUT} ${NODES_SOURCE_OUTPUT})

list(APPEND IR_SOURCES ${CMAKE_CURRENT_BINARY_DIR/xls/ir/nodes.cc})

# --

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

# -- 

# -- ir_converter_main

# Add source files for ir_converter_main
set(IR_CONVERTER_MAIN_SOURCES
    ${XLS_REPO_DIR}/xls/dslx/ir_convert/ir_converter_main.cc
    # Add any additional source files required by ir_converter_main here
    ${COMMON_SOURCES}
)

# Create an executable target for ir_converter_main
add_executable(ir_converter_main ${IR_CONVERTER_MAIN_SOURCES})

target_include_directories(ir_converter_main PUBLIC
    ${XLS_REPO_DIR}
    ${LLVM_INCLUDE_DIRS}
    ${Z3_INCLUDE_DIRS}
    ${GTEST_DIR}/googletest/include
    ${GTEST_DIR}/googlemock/include
    ${benchmark_INCLUDE_DIRS}
    ${Protobuf_INCLUDE_DIR}
    ${RE2_DIR}/re2
)

# Link dependencies for ir_converter_main
target_link_libraries(ir_converter_main
    ${LLVM_LIBRARIES}
    ${Z3_TARGET}
    re2
    GTest::gtest
    GTest::gtest_main
    GTest::gmock
    GTest::gmock_main
    benchmark::benchmark
    protobuf::libprotobuf
    absl::base
    absl::synchronization
    absl::strings
)

# Define the proto files
set(PROTO_FILES
    ${XLS_REPO_DIR}/xls/ir/foreign_function_data.proto
    ${XLS_REPO_DIR}/xls/ir/xls_type.proto
    ${XLS_REPO_DIR}/xls/ir/xls_value.proto
    ${XLS_REPO_DIR}/xls/fuzzer/ast_generator_options.proto
    # Add more proto files here as needed
)

# Define the output directory for the generated files
set(PROTO_SRCS)
set(PROTO_HDRS)
foreach(PROTO ${PROTO_FILES})
    file(RELATIVE_PATH PROTO_REL_PATH ${XLS_REPO_DIR} ${PROTO})
    get_filename_component(PROTO_DIR ${PROTO_REL_PATH} DIRECTORY)
    get_filename_component(PROTO_NAME ${PROTO} NAME_WE)
    list(APPEND PROTO_SRCS "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_DIR}/${PROTO_NAME}.pb.cc")
    list(APPEND PROTO_HDRS "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_DIR}/${PROTO_NAME}.pb.h")
endforeach()

# Add custom command to generate protobuf files
add_custom_command(
    OUTPUT ${PROTO_SRCS} ${PROTO_HDRS}
    COMMAND ${Protobuf_PROTOC_EXECUTABLE}
    ARGS --experimental_allow_proto3_optional --cpp_out ${CMAKE_CURRENT_BINARY_DIR} --proto_path ${XLS_REPO_DIR} ${PROTO_FILES}
    DEPENDS ${PROTO_FILES}
    COMMENT "Running C++ protocol buffer compiler on ${PROTO_FILES} hdrs: ${PROTO_HDRS} srcs: ${PROTO_SRCS}"
    VERBATIM
)

# Create a target to hold the generated files
add_custom_target(proto_gen ALL DEPENDS ${PROTO_SRCS} ${PROTO_HDRS})

# -- mangle_test

# Create an executable target for the test
add_executable(mangle_test
    ${XLS_REPO_DIR}/xls/dslx/mangle_test.cc
    ${DSLX_SOURCES}
    ${IR_SOURCES}
)

add_dependencies(mangle_test proto_gen)

# Include directories for the test
target_include_directories(mangle_test PUBLIC
    ${XLS_REPO_DIR}
    ${LLVM_INCLUDE_DIRS}
    ${GTEST_DIR}/googletest/include
    ${GTEST_DIR}/googlemock/include
    ${benchmark_INCLUDE_DIRS}
    ${Protobuf_INCLUDE_DIR}
    ${RE2_DIR}/re2
    ${CMAKE_CURRENT_BINARY_DIR}
    ${OPENSSL_INCLUDE_DIR}
)

# Link dependencies for the test
target_link_libraries(mangle_test
    ${LLVM_LIBRARIES}
    re2
    GTest::gtest
    GTest::gtest_main
    GTest::gmock
    GTest::gmock_main
    benchmark::benchmark
    protobuf::libprotobuf
    absl::base
    absl::synchronization
    absl::strings
    OpenSSL::SSL
    OpenSSL::Crypto
)

# Add the test to CTest
add_test(NAME mangle_test COMMAND mangle_test)
