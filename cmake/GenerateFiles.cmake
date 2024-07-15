# Define paths for the template and output
set(OP_HEADER_TEMPLATE "${XLS_REPO_DIR}/xls/ir/op_header.tmpl")
set(OP_HEADER_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/xls/ir/op.h")

# Ensure the output directory exists
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/xls/ir")

# Custom command to generate op.h
add_custom_command(
    OUTPUT ${OP_HEADER_OUTPUT}
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${XLS_REPO_DIR}  ${PYTHON_EXECUTABLE} ${XLS_REPO_DIR}/xls/ir/render_specification_against_template.py ${OP_HEADER_TEMPLATE} > ${OP_HEADER_OUTPUT}
    COMMAND clang-format -i ${OP_HEADER_OUTPUT}
    DEPENDS ${OP_HEADER_TEMPLATE} ${XLS_REPO_DIR}/xls/ir/render_specification_against_template.py
    COMMENT "Generating and formatting op.h"
    VERBATIM
)

# Custom target to run the custom command
add_custom_target(generate_op_header ALL DEPENDS ${OP_HEADER_OUTPUT})

# -- protos

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
