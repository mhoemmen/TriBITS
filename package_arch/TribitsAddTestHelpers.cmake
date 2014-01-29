# @HEADER
# ************************************************************************
#
#            TriBITS: Tribial Build, Integrate, and Test System
#                    Copyright 2013 Sandia Corporation
#
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the Corporation nor the names of the
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY SANDIA CORPORATION "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL SANDIA CORPORATION OR THE
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ************************************************************************
# @HEADER


INCLUDE(TribitsAddExecutableTestHelpers)

INCLUDE(ParseVariableArguments)
INCLUDE(GlobalSet)
INCLUDE(AppendGlobalSet)
INCLUDE(PrintVar)
INCLUDE(AdvancedSet)
INCLUDE(MessageWrapper)


#
# Function that converts a complete string of command-line arguments
# into a form that ADD_TEST(...) can correctly deal with.
#
# The main thing this function does is to replace spaces ' ' with
# array separators ';' since this is how ADD_TEST(...) expects to deal
# with command-line arguments, as array arguments.  However, this
# function will not do a replacement of ' ' with ';' if a quote is
# active.  This allows you to pass in quoted arguments and have them
# treated as a single argument.
#

FUNCTION(TRIBITS_CONVERT_CMND_ARG_STRING_TO_ADD_TEST_ARG_ARRAY CMND_ARG_STRING ARG_ARRAY_VARNAME)
  
  #MESSAGE("TRIBITS_CONVERT_CMND_ARG_STRING_TO_ADD_TEST_ARG_ARRAY")
  #PRINT_VAR(CMND_ARG_STRING)
  #PRINT_VAR(ARG_ARRAY_VARNAME)

  STRING(LENGTH ${CMND_ARG_STRING} STR_LEN)
  #PRINT_VAR(STR_LEN)

  MATH(EXPR STR_LAST_IDX "${STR_LEN}-1")

  SET(NEWSTR)

  SET(ACTIVE_QUOTE OFF)

  FOREACH(IDX RANGE ${STR_LAST_IDX})

    STRING(SUBSTRING ${CMND_ARG_STRING} ${IDX} 1 STR_CHAR)
    #PRINT_VAR(STR_CHAR)

    IF (STR_CHAR STREQUAL "\"")
      IF (NOT ACTIVE_QUOTE)
        SET(ACTIVE_QUOTE ON)
      ELSE()
        SET(ACTIVE_QUOTE OFF)
      ENDIF()
      #PRINT_VAR(ACTIVE_QUOTE)
    ENDIF()

    IF (NOT STR_CHAR STREQUAL " ")
      SET(NEWSTR "${NEWSTR}${STR_CHAR}")
    ELSE()
      IF (ACTIVE_QUOTE)
        SET(NEWSTR "${NEWSTR}${STR_CHAR}")
      ELSE()
        SET(NEWSTR "${NEWSTR};")
      ENDIF()
    ENDIF()

  ENDFOREACH()
   
  #PRINT_VAR(NEWSTR)

  SET(${ARG_ARRAY_VARNAME} ${NEWSTR} PARENT_SCOPE)

ENDFUNCTION()


#
# Determine if to add the test or not based on [X]HOST and [X]HOSTTYPE arguments
#
# Warning: Arguments for [X]HOST and [X]HOSTTYPE arguments are passed in
# implicitly due to scoping of CMake.
#

FUNCTION(TRIBITS_ADD_TEST_PROCESS_HOST_HOSTTYPE  ADD_THE_TEST_OUT)

  SET(ADD_THE_TEST TRUE)

  IF (NOT PARSE_HOST)
    SET (PARSE_HOST ${${PROJECT_NAME}_HOSTNAME})
  ENDIF()  
  LIST (FIND PARSE_HOST ${${PROJECT_NAME}_HOSTNAME} INDEX_OF_HOSTNAME_IN_HOST_LIST)                 
  IF (${INDEX_OF_HOSTNAME_IN_HOST_LIST} EQUAL -1)
    SET(ADD_THE_TEST FALSE)
  ENDIF()
  
  IF (NOT PARSE_XHOST)
    SET (PARSE_XHOST NONE)
  ENDIF()    
  LIST (FIND PARSE_XHOST ${${PROJECT_NAME}_HOSTNAME} INDEX_OF_HOSTNAME_IN_XHOST_LIST)           
  IF (NOT ${INDEX_OF_HOSTNAME_IN_XHOST_LIST} EQUAL -1)
    SET(ADD_THE_TEST FALSE)
  ENDIF()

  IF (NOT PARSE_HOSTTYPE)
    SET(PARSE_HOSTTYPE ${CMAKE_HOST_SYSTEM_NAME})
  ENDIF()
  LIST (FIND PARSE_HOSTTYPE ${CMAKE_HOST_SYSTEM_NAME} INDEX_OF_HOSTSYSTEMNAME_IN_HOSTTYPE_LIST)
  IF (${INDEX_OF_HOSTSYSTEMNAME_IN_HOSTTYPE_LIST} EQUAL -1)
    SET(ADD_THE_TEST FALSE)
  ENDIF()

  IF (NOT PARSE_XHOSTTYPE)
    SET(PARSE_XHOSTTYPE NONE)
  ENDIF()
  LIST (FIND PARSE_XHOSTTYPE ${CMAKE_HOST_SYSTEM_NAME} INDEX_OF_HOSTSYSTEMNAME_IN_XHOSTTYPE_LIST)
  IF (NOT ${INDEX_OF_HOSTSYSTEMNAME_IN_XHOSTTYPE_LIST} EQUAL -1)
    SET(ADD_THE_TEST FALSE)
  ENDIF()

  SET(${ADD_THE_TEST_OUT} ${ADD_THE_TEST} PARENT_SCOPE)

ENDFUNCTION()


#
# Determine if to add the test or not based on CATEGORIES arguments
#
# Warning: Argument PARSE_CATEGORIES is passed in implicitly due to scoping of
# CMake.
# 

FUNCTION(TRIBITS_ADD_TEST_PROCESS_CATEGORIES  ADD_THE_TEST_OUT)

  TRIBITS_ASSERT_VALID_CATEGORIES(${PARSE_CATEGORIES})

  SET(ADD_THE_TEST FALSE)

  # Set the default test-specific cateogry to basic if it is not set
  IF (NOT PARSE_CATEGORIES)
    SET (PARSE_CATEGORIES BASIC)
  ENDIF()

  #PRINT_VAR(${PROJECT_NAME}_TEST_CATEGORIES)
  #PRINT_VAR(PARSE_CATEGORIES)

  # Process the test categories
  ASSERT_DEFINED(${PROJECT_NAME}_TEST_CATEGORIES)
  FOREACH(CATEGORY_USR_SET ${${PROJECT_NAME}_TEST_CATEGORIES})
    #PRINT_VAR(CATEGORY_USR_SET)
    #PRINT_VAR(PARSE_CATEGORIES)
    FOREACH(CATEGORY ${PARSE_CATEGORIES})
      IF (CATEGORY STREQUAL ${CATEGORY_USR_SET})
        # Exact match for the category, add the test
        SET(ADD_THE_TEST TRUE)
      ELSEIF(CATEGORY STREQUAL "BASIC")
        IF (CATEGORY_USR_SET STREQUAL "CONTINUOUS" OR CATEGORY_USR_SET STREQUAL "NIGHTLY"
          OR CATEGORY_USR_SET STREQUAL "WEEKLY"
          )
          SET(ADD_THE_TEST TRUE)
        ENDIF()
      ELSEIF(CATEGORY STREQUAL "CONTINUOUS")
        IF (CATEGORY_USR_SET STREQUAL "NIGHTLY" OR CATEGORY_USR_SET STREQUAL "WEEKLY")
          SET(ADD_THE_TEST TRUE)
        ENDIF()
      ELSEIF(CATEGORY STREQUAL "NIGHTLY")
        IF (CATEGORY_USR_SET STREQUAL "WEEKLY")
          SET(ADD_THE_TEST TRUE)
        ENDIF()
      ELSE()
        # No matches for the category, don't add the test
      ENDIF()
    ENDFOREACH()
  ENDFOREACH()

  SET(${ADD_THE_TEST_OUT} ${ADD_THE_TEST} PARENT_SCOPE)
  #PRINT_VAR(${ADD_THE_TEST_OUT})

ENDFUNCTION()


#
# Get the full name of a package executable given its root name
#

FUNCTION(TRIBITS_ADD_TEST_GET_EXE_BINARY_NAME  EXE_NAME_IN
  NOEXEPREFIX_IN  NOEXESUFFIX_IN ADD_DIR_TO_NAME EXE_BINARY_NAME_OUT
  )
  SET(EXE_BINARY_NAME "${EXE_NAME_IN}")
  IF(PARSE_ADD_DIR_TO_NAME)
    SET(DIRECTORY_NAME "")
    TRIBITS_CREATE_NAME_FROM_CURRENT_SOURCE_DIRECTORY(DIRECTORY_NAME)
    SET(EXE_BINARY_NAME "${DIRECTORY_NAME}_${EXE_BINARY_NAME}")
  ENDIF()
  IF (NOT NOEXESUFFIX_IN)
    SET(EXE_BINARY_NAME "${EXE_BINARY_NAME}${CMAKE_EXECUTABLE_SUFFIX}")
  ENDIF()
  IF(PACKAGE_NAME AND NOT NOEXEPREFIX_IN)
    SET(EXE_BINARY_NAME ${PACKAGE_NAME}_${EXE_BINARY_NAME})
  ENDIF()
  SET(${EXE_BINARY_NAME_OUT} ${EXE_BINARY_NAME} PARENT_SCOPE)
ENDFUNCTION()


#
# Adjust the directory path to an executable for a test
#

FUNCTION(TRIBITS_ADD_TEST_ADJUST_DIRECTORY  EXE_BINARY_NAME  DIRECTORY  EXECUTABLE_PATH_OUT)

   IF (DIRECTORY)
     SET(EXECUTABLE_PATH "${DIRECTORY}/${EXE_BINARY_NAME}")
   ELSE()
     SET(EXECUTABLE_PATH "${EXE_BINARY_NAME}")
   ENDIF()

   IF (NOT IS_ABSOLUTE ${EXECUTABLE_PATH})
     SET(EXECUTABLE_PATH "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_PATH}")
   ENDIF()

  SET(${EXECUTABLE_PATH_OUT} ${EXECUTABLE_PATH} PARENT_SCOPE)

ENDFUNCTION()


#
# Get the number of MPI processes to use
#

FUNCTION(TRIBITS_ADD_TEST_GET_NUM_PROCS_USED  NUM_MPI_PROCS_IN
  NUM_MPI_PROCS_USED_OUT
  )
  IF (NOT DEFINED MPI_EXEC_DEFAULT_NUMPROCS)
    SET(MPI_EXEC_DEFAULT_NUMPROCS 1)
  ENDIF()
  IF (NOT DEFINED MPI_EXEC_MAX_NUMPROCS)
    SET(MPI_EXEC_MAX_NUMPROCS 1)
  ENDIF()
  IF (NOT NUM_MPI_PROCS_IN)
    SET(NUM_MPI_PROCS_IN ${MPI_EXEC_DEFAULT_NUMPROCS})
  ENDIF()
  IF(${NUM_MPI_PROCS_IN} MATCHES [0-9]+-[0-9]+)
    STRING(REGEX REPLACE "([0-9]+)-([0-9]+)" "\\1" MIN_NP ${NUM_MPI_PROCS_IN} )
    STRING(REGEX REPLACE "([0-9]+)-([0-9]+)" "\\2" MAX_NP ${NUM_MPI_PROCS_IN} )
    IF(${MIN_NP} LESS ${MPI_EXEC_MAX_NUMPROCS} AND ${MAX_NP} GREATER ${MPI_EXEC_MAX_NUMPROCS} )
      SET(NUM_PROCS_USED ${MPI_EXEC_MAX_NUMPROCS})
    ELSEIF(${MIN_NP} EQUAL ${MPI_EXEC_MAX_NUMPROCS})
      SET(NUM_PROCS_USED ${MIN_NP})
    ELSEIF(${MAX_NP} EQUAL ${MPI_EXEC_MAX_NUMPROCS})
      SET(NUM_PROCS_USED ${MAX_NP})
    ELSEIF(${MAX_NP} LESS ${MPI_EXEC_MAX_NUMPROCS})
      SET(NUM_PROCS_USED ${MAX_NP})
    ELSE()
      # The number of available processor is outside the given range
      # so the test should not be run.
      SET(NUM_PROCS_USED -1)
    ENDIF()
  ELSEIF(${NUM_MPI_PROCS_IN} MATCHES [0-9]+,[0-9]+)
    MESSAGE(SEND_ERROR "The test ${TEST_NAME} can not be added yet"
      " because it we do not yet support the form of"
      " NUM_MPI_PROCS=${NUM_MPI_PROCS_IN}") 
      SET(NUM_PROCS_USED -1)
  ELSE()
    IF(${NUM_MPI_PROCS_IN} GREATER ${MPI_EXEC_MAX_NUMPROCS})
      SET(NUM_PROCS_USED -1)
    ELSE()
      SET(NUM_PROCS_USED ${NUM_MPI_PROCS_IN})
    ENDIF()
  ENDIF()
  SET(${NUM_MPI_PROCS_USED_OUT} ${NUM_PROCS_USED} PARENT_SCOPE)
ENDFUNCTION()


#
# Generate the array of arguments for an MPI run
#
# NOTE: The extra test program arguments are passed through ${ARGN}.
#

FUNCTION( TRIBITS_ADD_TEST_GET_TEST_CMND_ARRAY  CMND_ARRAY_OUT
  EXECUTABLE_PATH  NUM_PROCS_USED
  )
  IF (TPL_ENABLE_MPI)
    SET(${CMND_ARRAY_OUT}
       "${MPI_EXEC}"
       ${MPI_EXEC_PRE_NUMPROCS_FLAGS}
       ${MPI_EXEC_NUMPROCS_FLAG} ${NUM_PROCS_USED}
       ${MPI_EXEC_POST_NUMPROCS_FLAGS}
       "${EXECUTABLE_PATH}"
       ${ARGN}
       PARENT_SCOPE
       )
   ELSE()
    SET(${CMND_ARRAY_OUT}
       "${EXECUTABLE_PATH}"
       ${ARGN}
       PARENT_SCOPE
       )
   ENDIF()
ENDFUNCTION()



#
# Determine if the test should be skipped due to a disable
#

FUNCTION(TRIBITS_ADD_TEST_QUERY_DISABLE DISABLE_TEST_VAR_OUT )

  #MESSAGE("TRIBITS_ADD_TEST_QUERY_DISABLE(): ${DISABLE_TEST_VAR_OUT} ${ARGN}")
  LIST(GET ARGN 0 TEST_NAME_IN)
  SET(TEST_NAME_DISABLE_VAR ${TEST_NAME_IN}_DISABLE)
  #PRINT_VAR(${TEST_NAME_DISABLE_VAR})
  IF (${TEST_NAME_DISABLE_VAR})
    MESSAGE(
      "WARNING: ${TEST_NAME_DISABLE_VAR}=${${TEST_NAME_DISABLE_VAR}}, skipping test ${TEST_NAME_IN}!")
    SET(${DISABLE_TEST_VAR_OUT} ON PARENT_SCOPE)
  ELSE()
    SET(${DISABLE_TEST_VAR_OUT} OFF PARENT_SCOPE)
  ENDIF()

ENDFUNCTION()


#
# Wrapper for adding a test to facilitate unit testing
#

FUNCTION(TRIBITS_ADD_TEST_ADD_TEST TEST_NAME EXE_NAME)

  IF (PACKAGE_ADD_TEST_ADD_TEST_CAPTURE)
    APPEND_GLOBAL_SET(PACKAGE_ADD_TEST_ADD_TEST_INPUT ${TEST_NAME} ${ARGN})
  ENDIF()

  IF (NOT PACKAGE_ADD_TEST_ADD_TEST_SKIP)
    ADD_TEST(${TEST_NAME} ${ARGN})
    SET_TESTS_PROPERTIES(${TEST_NAME} PROPERTIES REQUIRED_FILES ${EXE_NAME})
  ENDIF()

ENDFUNCTION()


#
# Set the pass/fail properties of a test that has already been added
#

MACRO(TRIBITS_PRIVATE_ADD_TEST_SET_PASS_PROPERTY TEST_NAME_IN)

  # PASS_REGULAR_EXPRESSION

  IF (PARSE_STANDARD_PASS_OUTPUT)
    SET_TESTS_PROPERTIES(${TEST_NAME_IN} PROPERTIES PASS_REGULAR_EXPRESSION
      "End Result: TEST PASSED")
  ENDIF()

  IF (PARSE_PASS_REGULAR_EXPRESSION)
    SET_TESTS_PROPERTIES(${TEST_NAME_IN} PROPERTIES PASS_REGULAR_EXPRESSION
      ${PARSE_PASS_REGULAR_EXPRESSION})
  ENDIF()

  IF (PARSE_WILL_FAIL)
    SET_TESTS_PROPERTIES(${TEST_NAME_IN} PROPERTIES WILL_FAIL ON)
  ENDIF()

  # FAIL_REGULAR_EXPRESSION

  SET(FAIL_REGEX_STRINGS "")

  IF (PARSE_FAIL_REGULAR_EXPRESSION)
    IF (FAIL_REGEX_STR)
      SET(FAIL_REGEX_STRINGS "${FAIL_REGEX_STRINGS};${PARSE_FAIL_REGULAR_EXPRESSION}")
    ELSE()
      SET(FAIL_REGEX_STRINGS "${PARSE_FAIL_REGULAR_EXPRESSION}")
    ENDIF()
  ENDIF()

  IF (${PACKAGE_NAME}_ENABLE_CIRCULAR_REF_DETECTION_FAILURE OR
    ${PROJECT_NAME}_ENABLE_CIRCULAR_REF_DETECTION_FAILURE
    )
    SET(CIR_REF_MSG "The following Teuchos::RCPNode objects were created")
    # NOTE: The above string must be kept in sync with the C++ code!
    IF (FAIL_REGEX_STR)
      SET(FAIL_REGEX_STRINGS "${FAIL_REGEX_STRINGS};${CIR_REF_MSG}")
    ELSE()
      SET(FAIL_REGEX_STRINGS "${CIR_REF_MSG}")
    ENDIF()
  ENDIF()

  IF (FAIL_REGEX_STRINGS)
    SET_TESTS_PROPERTIES(${TEST_NAME_IN} PROPERTIES FAIL_REGULAR_EXPRESSION
     "${FAIL_REGEX_STRINGS}")
  ENDIF()

  IF (PARSE_TIMEOUT)
    SET_TESTS_PROPERTIES(${TEST_NAME_IN} PROPERTIES TIMEOUT ${PARSE_TIMEOUT})
  ENDIF()

  IF (PARSE_ENVIRONMENT)
    SET_PROPERTY(TEST ${TEST_NAME_IN} PROPERTY ENVIRONMENT ${PARSE_ENVIRONMENT})
  ENDIF()

ENDMACRO()


#
# Overall add test command
#
# NOTE: Pass the command arguments on the end!
#

FUNCTION(TRIBITS_ADD_TEST_ADD_TEST_ALL  TEST_NAME_IN 
  EXECUTABLE_PATH_IN  NUM_PROCS_USED_IN  CREATE_WORKING_DIR_IN  RUN_SERIAL_IN
  )

  IF (CREATE_WORKING_DIR_IN)

    MESSAGE(FATAL_ERROR "ToDo: Impement the CREATE_WORKING_DIR case!")

  ELSE()

    SET(FULL_TEST_NAME "${PACKAGE_NAME}_${TEST_NAME_IN}")
    
    TRIBITS_ADD_TEST_GET_TEST_CMND_ARRAY( CMND_ARRAY
      "${EXECUTABLE_PATH_IN}"  "${NUM_PROCS_USED_IN}" ${ARGN} )

    TRIBITS_ADD_TEST_QUERY_DISABLE(DISABLE_THIS_TEST ${FULL_TEST_NAME})

    IF (NOT DISABLE_THIS_TEST)
    
      TRIBITS_ADD_TEST_ADD_TEST( ${FULL_TEST_NAME} ${EXECUTABLE_PATH_IN} ${CMND_ARRAY} )
    
      TRIBITS_PRIVATE_ADD_TEST_POST_PROCESS_ADDED_TEST(${FULL_TEST_NAME})

    ENDIF()

  ENDIF()

ENDFUNCTION()


#
# Set the label and keywords
#

MACRO(TRIBITS_PRIVATE_ADD_TEST_ADD_LABEL_AND_KEYWORDS  TEST_NAME_IN)

  IF (NOT PACKAGE_ADD_TEST_ADD_TEST_SKIP)
    SET_PROPERTY(TEST ${TEST_NAME_IN} APPEND PROPERTY
      LABELS ${PARENT_PACKAGE_NAME})
    IF(PARSE_KEYWORDS)
      SET_PROPERTY(TEST ${TEST_NAME_IN} APPEND PROPERTY
        LABELS ${PARSE_KEYWORDS})
    ENDIF()
  ENDIF()

ENDMACRO()


#
# Postprocess a test that was added
#

MACRO(TRIBITS_PRIVATE_ADD_TEST_POST_PROCESS_ADDED_TEST  TEST_NAME_IN)

  IF (NOT PACKAGE_ADD_TEST_ADD_TEST_CAPTURE)
  
    TRIBITS_PRIVATE_ADD_TEST_SET_PASS_PROPERTY(${TEST_NAME_IN})
  
    IF(NUM_PROCS_USED)
      SET_TESTS_PROPERTIES(${FULL_TEST_NAME} PROPERTIES PROCESSORS
        "${NUM_PROCS_USED_IN}")
    ENDIF()
    
    IF(RUN_SERIAL_IN)
      SET_TESTS_PROPERTIES(${FULL_TEST_NAME} PROPERTIES RUN_SERIAL ON)
    ENDIF()
  
    TRIBITS_PRIVATE_ADD_TEST_ADD_LABEL_AND_KEYWORDS(${TEST_NAME_IN})

  ENDIF()

ENDMACRO()


