# targets.cmake
#
# Copyright (c) 2019 - BladeRunner Labs
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software")
# to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# include dependencies
if (NOT _MESSAGES_CMAKE_INCLUDED)
    include(${INC_CMAKE_DIR}/messages.cmake)
endif()

if (NOT _TARGETS_CMAKE_INCLUDED)
set(_TARGETS_CMAKE_INCLUDED YES)

function(define_lib lib_name)
    # parse arguments
    set(args_options )
    set(args_single API_DIR SRC_DIR)
    set(args_multi SOURCES PRIV_HEADERS API_HEADERS DEFS_ADD LIBS SYS_LIBS)

    cmake_parse_arguments("LIB" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    if(LIB_UNPARSED)
        message("Unparsed arguments for define_lib(${lib_name}: ${LIB_UNPARSED}")
    endif()

    # transform some arguments
    if(LIB_API_DIR)
        set(API_DIR ${LIB_API_DIR})
    endif()
    if(LIB_SRC_DIR)
        set(SRC_DIR ${LIB_SRC_DIR})
    endif()

    set(FULL_PATH_API_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${API_DIR}")

    if(NOT ${API_DIR} STREQUAL ".")
        foreach(hdr ${LIB_API_HEADERS})
            list(APPEND RELATIVE_API_HEADERS "${API_DIR}/${hdr}")
        endforeach(hdr)
    else()
        set(RELATIVE_API_HEADERS ${LIB_API_HEADERS})
    endif()

    if(NOT ${SRC_DIR} STREQUAL ".")
        foreach(src ${LIB_SOURCES})
            list(APPEND RELATIVE_SOURCES "${SRC_DIR}/${src}")
        endforeach(src)

        foreach(phdr ${LIB_PRIV_HEADERS})
            list(APPEND RELATIVE_PRIV_HEADERS "${SRC_DIR}/${phdr}")
        endforeach(phdr)
    else()
        set(RELATIVE_SOURCES ${LIB_SOURCES})
        set(RELATIVE_PRIV_HEADERS ${LIB_PRIV_HEADERS})
    endif()

    set(INSTALL_API_HEADERS ${LIB_API_HEADERS})

    # declare new lib project
    project(${lib_name} )

    add_library(${PROJECT_NAME}
        ${RELATIVE_SOURCES}
        ${RELATIVE_PRIV_HEADERS}
        ${RELATIVE_API_HEADERS}
    )
    set_target_properties(${PROJECT_NAME} PROPERTIES
        PUBLIC_HEADER "${RELATIVE_API_HEADERS}"
    )
    set_source_files_properties(
        ${RELATIVE_API_HEADERS} ${RELATIVE_PRIV_HEADERS} PROPERTIES
        HEADER_FILE_ONLY ON
    )
    # create alias with the namespace
    add_library(${NAMESPACE_NAME}${PROJECT_NAME}
        ALIAS ${PROJECT_NAME}
    )
    # add compile-time definitions
    target_compile_definitions(${PROJECT_NAME} PUBLIC
        ${LIB_DEFS_ADD}
    )
    # define include dirs for private and public use
    target_include_directories(${PROJECT_NAME} PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    )
    target_include_directories(${PROJECT_NAME} PUBLIC
        $<BUILD_INTERFACE:${FULL_PATH_API_DIR}>
    )
    target_include_directories(${PROJECT_NAME} INTERFACE
        $<INSTALL_INTERFACE:${PACKAGE_NAME}/include>
    )
    #define libraries to link with
    target_link_libraries(${PROJECT_NAME}
        ${LIB_LIBS}
        ${LIB_SYS_LIBS}
    )
    # define install policies
    install(TARGETS ${PROJECT_NAME}
        EXPORT ${EXPORT_NAME}
        ARCHIVE DESTINATION ${PACKAGE_INSTALL_PREFIX}/lib
        LIBRARY DESTINATION ${PACKAGE_INSTALL_PREFIX}/lib
        RUNTIME DESTINATION ${PACKAGE_INSTALL_PREFIX}/bin
        PUBLIC_HEADER DESTINATION ${PACKAGE_INSTALL_PREFIX}/include
        INCLUDES DESTINATION ${PACKAGE_INSTALL_PREFIX}/include
    )
    install(EXPORT ${EXPORT_NAME}
        NAMESPACE ${NAMESPACE_NAME}
        DESTINATION ${PACKAGE_NAME}
        FILE ${EXPORT_FILE}
    )
    export(EXPORT ${EXPORT_NAME}
        NAMESPACE ${NAMESPACE_NAME}
    )

    msg_green("Added LIBRARY: ${PROJECT_NAME}")
endfunction() # define_lib

function(define_api api_name)
    # parse arguments
    set(args_options )
    set(args_single API_DIR INSTALL_DIR)
    set(args_multi API_HEADERS)

    cmake_parse_arguments("API" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    if(API_UNPARSED)
        message("Unparsed arguments for define_api(${api_name}: ${API_UNPARSED}")
    endif()

    if (NOT API_INSTALL_DIR)
        set(API_INSTALL_DIR include)
    else()
        set(API_INSTALL_DIR include/${API_INSTALL_DIR})
    endif()

    # transform some arguments
    if(API_API_DIR)
        set(API_DIR ${API_API_DIR})
    endif()

    set(FULL_PATH_API_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${API_DIR}")

    foreach(hdr ${API_API_HEADERS})
        list(APPEND RELATIVE_API_HEADERS "${API_DIR}/${hdr}")
    endforeach(hdr)

    set(INSTALL_API_HEADERS ${API_API_HEADERS})

    # declare new api project
    project(${api_name})

    add_library(${PROJECT_NAME} INTERFACE
    )
    # create alias with the namespace
    add_library(${NAMESPACE_NAME}${PROJECT_NAME}
        ALIAS ${PROJECT_NAME}
    )
    # define include dirs for private and public use
    target_include_directories(${PROJECT_NAME} INTERFACE
        $<BUILD_INTERFACE:${FULL_PATH_API_DIR}>
        $<INSTALL_INTERFACE:${API_INSTALL_DIR}>
    )
    # install header files
    install(FILES ${RELATIVE_API_HEADERS}
        DESTINATION ${PACKAGE_INSTALL_PREFIX}/${API_INSTALL_DIR}
    )
    # define install policies
    install(TARGETS ${PROJECT_NAME}
        EXPORT ${EXPORT_NAME}
        INCLUDES ${API_INSTALL_DIR}
    )
    install(EXPORT ${EXPORT_NAME}
        NAMESPACE ${NAMESPACE_NAME}
        DESTINATION ${PACKAGE_NAME}
        FILE ${EXPORT_FILE}
    )
    export(EXPORT ${EXPORT_NAME}
        NAMESPACE ${NAMESPACE_NAME}
    )

    msg_green("Added API: ${PROJECT_NAME}")
endfunction() # define_api

function(define_app app_name)
    # parse arguments
    set(args_options UTEST)
    set(args_single API_DIR SRC_DIR INSTALL_DIR)
    set(args_multi SOURCES PRIV_HEADERS API_HEADERS DEFS_ADD LIBS SYS_LIBS LINK_OPTS FILES)

    cmake_parse_arguments("APP" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    if(APP_UNPARSED)
        msg_red("Unparsed arguments for define_app(${app_name}: ${APP_UNPARSED}")
    endif()

    if(APP_API_DIR)
        set(API_DIR ${APP_API_DIR})
    endif()

    if(NOT APP_INSTALL_DIR)
        set(APP_INSTALL_DIR bin)
    endif()

    # transform some arguments
    foreach(hdr ${APP_API_HEADERS})
        list(APPEND API_HEADERS "${API_DIR}/${hdr}")
    endforeach(hdr)

    if(APP_SRC_DIR)
        set(SRC_DIR ${APP_SRC_DIR})
    endif()

    if(NOT ${SRC_DIR} STREQUAL ".")
        foreach(src ${APP_SOURCES})
            list(APPEND RELATIVE_SOURCES "${SRC_DIR}/${src}")
        endforeach(src)

        foreach(phdr ${APP_PRIV_HEADERS})
            list(APPEND RELATIVE_PRIV_HEADERS "${SRC_DIR}/${phdr}")
        endforeach(phdr)
    else()
        set(RELATIVE_SOURCES ${APP_SOURCES})
        set(RELATIVE_PRIV_HEADERS ${APP_PRIV_HEADERS})
    endif()

    # declare new app project
    project(${app_name})

    add_executable(${PROJECT_NAME}
        ${RELATIVE_SOURCES}
        ${RELATIVE_PRIV_HEADERS}
        ${API_HEADERS}
    )
    # define include dirs for private and public use
    target_include_directories(${PROJECT_NAME} PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    )
    if(API_HEADERS)
        target_include_directories(${PROJECT_NAME} PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${API_DIR}>
        )
    endif()
    target_include_directories(${PROJECT_NAME} INTERFACE
        $<INSTALL_INTERFACE:include>
    )
    # add compile-time definitions
    target_compile_definitions(${PROJECT_NAME} PRIVATE
        ${APP_DEFS_ADD}
    )

    #define libraries to link with
    target_link_libraries(${PROJECT_NAME}
        ${APP_LIBS}
        ${APP_SYS_LIBS}
        "${APP_LINK_OPTS}"
    )
    # define install policies
    install(FILES ${API_HEADERS}
        DESTINATION ${PACKAGE_INSTALL_PREFIX}/include
    )
    install(TARGETS ${PROJECT_NAME}
        EXPORT ${EXPORT_NAME}
        RUNTIME DESTINATION ${PACKAGE_INSTALL_PREFIX}/${APP_INSTALL_DIR}
    )
    install(FILES ${APP_FILES}
        DESTINATION ${PACKAGE_INSTALL_PREFIX}/${APP_INSTALL_DIR}
    )
    # setup export file
    install(EXPORT ${EXPORT_NAME}
        NAMESPACE ${NAMESPACE_NAME}
        DESTINATION ${PACKAGE_NAME}
        FILE ${EXPORT_FILE}
    )
    export(EXPORT ${EXPORT_NAME}
        NAMESPACE ${NAMESPACE_NAME}
    )

    if(NOT APP_UTEST)
        msg_green("Added APPLICATION: ${PROJECT_NAME}")
    else()
        msg_green("Added UNIT TEST: ${PROJECT_NAME}")
    endif()
endfunction() # define_app

function(define_utest utest_name)
    define_app(
        ${ARGV}
        UTEST
        INSTALL_DIR
            utest
    )
endfunction() # define_utest

function(define_batch batch_name)
    # parse arguments
    set(args_single INSTALL_DIR)
    set(args_multi FILES)

    cmake_parse_arguments("BATCH" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    if(BATCH_UNPARSED)
        msg_red("Unparsed arguments for define_batch(${batch_name}: ${BATCH_UNPARSED}")
    endif()

    if(NOT BATCH_INSTALL_DIR)
        set(BATCH_INSTALL_DIR .)
    endif()

    install(FILES ${BATCH_FILES}
        DESTINATION ${PACKAGE_INSTALL_PREFIX}/${BATCH_INSTALL_DIR}
    )
endfunction() # define_batch

endif (NOT _TARGETS_CMAKE_INCLUDED)
