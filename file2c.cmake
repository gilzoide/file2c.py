#[[
Generates a library target that builds and links a C variable containing the input file contents.
Two global variables are defined by the generated library:
- <symbol>: a pointer to the file contents
- <symbol>_size: the size of the file contents

Requires Python 3.12.

Usage:
add_file2c(
  <generated-target-name>
  INPUT <input-file>  # Input file name, required
  [SYMBOL <symbol>]  # Symbol used for the generated global variable.
                     # Defaults to the name of the <input-file> without extensions
  [TEXT]  # If passed, the variable is defined as "const char *" and is guaranteed to end in a null character.
          # Otherwise, the variable is defined as "const unsigned char *".
)
target_link_libraries(<target-that-uses-file-contents> <generated-target-name>)
]]
function(add_file2c arg_file2c_TARGET)
  set(options TEXT)
  set(oneValueArgs INPUT SYMBOL)
  set(multiValueArgs)
  cmake_parse_arguments(arg_file2c "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT DEFINED arg_file2c_TARGET)
    message(FATAL_ERROR "Target name argument is required")
  endif()
  if(NOT DEFINED arg_file2c_INPUT)
    message(FATAL_ERROR "INPUT argument is required")
  endif()
  if(NOT DEFINED arg_file2c_SYMBOL)
    get_filename_component(arg_file2c_SYMBOL "${arg_file2c_INPUT}" NAME_WE)
  endif()

  get_filename_component(arg_file2c_INPUT_ABSOLUTE "${arg_file2c_INPUT}" ABSOLUTE)

  set(file2c_py_args
    "${arg_file2c_INPUT_ABSOLUTE}"
    --symbol "${arg_file2c_SYMBOL}"
  )
  if(arg_file2c_TEXT)
    list(APPEND file2c_py_args "--text")
  endif()

  find_package(Python3 REQUIRED COMPONENTS Interpreter)
  set(arg_file2c_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/${arg_file2c_TARGET}")
  set(arg_file2c_C_OUTPUT "${arg_file2c_OUTPUT_DIR}/${arg_file2c_SYMBOL}.c")
  set(arg_file2c_H_OUTPUT "${arg_file2c_OUTPUT_DIR}/${arg_file2c_SYMBOL}.h")
  add_custom_command(
    OUTPUT
      "${arg_file2c_C_OUTPUT}"
    COMMAND
      ${Python3_EXECUTABLE} "${_file2c_py}" ${file2c_py_args} -o "${arg_file2c_C_OUTPUT}"
    DEPENDS
      "${_file2c_py}"
      "${arg_file2c_INPUT}"
  )
  add_custom_command(
    OUTPUT
      "${arg_file2c_H_OUTPUT}"
    COMMAND
      ${Python3_EXECUTABLE} "${_file2c_py}" ${file2c_py_args} -o "${arg_file2c_H_OUTPUT}" --header
    DEPENDS
      "${_file2c_py}"
  )
  add_library(${arg_file2c_TARGET} OBJECT
    "${arg_file2c_H_OUTPUT}"
    "${arg_file2c_C_OUTPUT}"
  )
  target_include_directories(${arg_file2c_TARGET}
    PUBLIC "${arg_file2c_OUTPUT_DIR}"
  )
endfunction()

# Store python script path before returning from `include(file2c.cmake)` to avoid losing CMAKE_CURRENT_LIST_DIR
set(_file2c_py "${CMAKE_CURRENT_LIST_DIR}/file2c.py")
