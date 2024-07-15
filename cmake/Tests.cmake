# -- xls/common/math_util_test

add_executable(xls_common_math_util_test
    ${XLS_REPO_DIR}/xls/common/math_util_test.cc
    ${DSLX_SOURCES}
    ${IR_SOURCES}
    ${COMMON_SOURCES}
)

add_dependencies(xls_common_math_util_test proto_gen)

# Include directories for the test
target_include_directories(xls_common_math_util_test PUBLIC
    ${PROJECT_INCLUDE_DIRS}
)

# Link dependencies for the test
target_link_libraries(xls_common_math_util_test
    ${PROJECT_LINK_LIBRARIES}
)

# Add the test to CTest
add_test(NAME xls_common_math_util_test COMMAND xls_common_math_util_test)

# -- xls/dslx/scanner_test

add_executable(xls_dslx_frontend_scanner_test
    ${XLS_REPO_DIR}/xls/dslx/frontend/scanner_test.cc
    ${DSLX_SOURCES}
    ${IR_SOURCES}
    ${COMMON_SOURCES}
)

add_dependencies(xls_dslx_frontend_scanner_test proto_gen)

# Include directories for the test
target_include_directories(xls_dslx_frontend_scanner_test PUBLIC
    ${PROJECT_INCLUDE_DIRS}
)

# Link dependencies for the test
target_link_libraries(xls_dslx_frontend_scanner_test
    ${PROJECT_LINK_LIBRARIES}
)

# Add the test to CTest
add_test(NAME xls_dslx_frontend_scanner_test COMMAND xls_dslx_frontend_scanner_test)

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
    ${PROJECT_INCLUDE_DIRS}
)

# Link dependencies for the test
target_link_libraries(mangle_test
    ${PROJECT_LINK_LIBRARIES}
)

# Add the test to CTest
add_test(NAME mangle_test COMMAND mangle_test)
