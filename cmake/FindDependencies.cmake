# Specify the submodule directories
set(ABSL_DIR ${CMAKE_SOURCE_DIR}/third_party/abseil)
set(GTEST_DIR ${CMAKE_SOURCE_DIR}/third_party/googletest)

find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

find_package(Z3 REQUIRED)
message(STATUS "Found Z3 ${Z3_VERSION}")
message(STATUS "Using Z3Config.cmake in: ${Z3_DIR}")

find_package(OpenSSL REQUIRED)
message(STATUS "Found OpenSSL ${OPENSSL_VERSION}")
message(STATUS "Using OpenSSL include directory: ${OPENSSL_INCLUDE_DIR}")

find_package(Protobuf REQUIRED)
message(STATUS "Found Protobuf ${Protobuf_VERSION}")
message(STATUS "Using Protobuf include directory: ${Protobuf_INCLUDE_DIR}")

find_package(benchmark REQUIRED)
message(STATUS "Found benchmark ${benchmark_VERSION}")
message(STATUS "Using benchmarkConfig.cmake in: ${benchmark_DIR}")

# Add the Abseil submodule
add_subdirectory(${ABSL_DIR})

# Add the Google Test and Google Mock submodule
add_subdirectory(${GTEST_DIR})

find_package(PythonInterp REQUIRED)

# Include directories
set(PROJECT_INCLUDE_DIRS
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

# Link libraries
set(PROJECT_LINK_LIBRARIES
    ${LLVM_LIBRARIES}
    ${Z3_TARGET}
    OpenSSL::SSL
    OpenSSL::Crypto
    protobuf::libprotobuf
    benchmark::benchmark
    GTest::gtest
    GTest::gtest_main
    GTest::gmock
    GTest::gmock_main
    re2
    absl::base
    absl::synchronization
    absl::strings
)
