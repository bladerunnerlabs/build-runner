# external.cmake
#
# Copyright (c) 2019 - BladeRunner Labs
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
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

if (NOT _PACKAGES_CMAKE_INCLUDED)
    include(${INC_CMAKE_DIR}/packages.cmake)
endif()

macro(set_global_var var_name)
    get_directory_property(_HAS_PARENT PARENT_DIRECTORY)
    if (_HAS_PARENT)
        set(${var_name} YES PARENT_SCOPE)
    else()
        set(${var_name} YES)
    endif()
endmacro(set_global_var)

# start the code
if (NOT _EXTERNAL_CMAKE_INCLUDED)
set_global_var(_EXTERNAL_CMAKE_INCLUDED)

include(ExternalProject)

macro(define_external_package name)
    # parse arguments
    set(args_options)
    set(args_single)
    set(args_multi FILES)

    cmake_parse_arguments("EXT_PACKAGE" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    if(EXT_PACKAGE_UNPARSED)
        message("Unparsed arguments for define_external_package(${name}: ${EXT_PACKAGE_UNPARSED}")
    endif()

    define_package(${name})

    # auto-generated library export file
    set(EXT_MISC_EXPORT_FILE ${PACKAGE_NAME}-libs-config.cmake)
    set(EXT_MISC_EXPORT_PATH ${PACKAGE_INSTALL_PREFIX}/${EXT_MISC_EXPORT_FILE})

    # parent target for all external projects
    set(EXT_PACKAGE_TARGET ${PACKAGE_NAME})
    add_custom_target(${EXT_PACKAGE_TARGET})

    # root installation dir
    set(EXT_PACKAGE_INSTALL_PREFIX ${PACKAGE_INSTALL_PREFIX})

    # misc files install dir (per project)
    set(EXT_INSTALL_FILES_DIR "misc")

    # install static root-level files
    if(BUILD_3RD_PARTY AND EXT_PACKAGE_FILES)
        msg_yellow("\n${name} external package, files to install: ${EXT_PACKAGE_FILES}")
        install(
            FILES ${EXT_PACKAGE_FILES}
            DESTINATION ${EXT_PACKAGE_INSTALL_PREFIX}
        )
    endif()

    # auto-generated file with external library import declarations
    set(MISC_EXPORT_FILE ${PACKAGE_NAME}-libs-config.cmake)
    set(EXT_MISC_EXPORT_PATH ${EXT_PACKAGE_INSTALL_PREFIX}/${MISC_EXPORT_FILE})
    file(WRITE ${EXT_MISC_EXPORT_PATH}
        "# ${EXT_MISC_EXPORT_PATH}\n# auto-generated imported library declaration list\n"
    )
endmacro(define_external_package)

macro(use_external_package)
    set(_USED_PACKAGE_NAME ${ARGV0})
    msg_green("use external package: ${_USED_PACKAGE_NAME}")

    set(_USED_PACKAGE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/${_USED_PACKAGE_NAME})

    set(_USED_PACKAGE_MISC_EXPORT_FILE ${_USED_PACKAGE_NAME}-libs-config.cmake)
    set(_USED_PACKAGE_MISC_EXPORT_PATH ${_USED_PACKAGE_INSTALL_PREFIX}/${_USED_PACKAGE_MISC_EXPORT_FILE})

    if(NOT ${_USED_PACKAGE_NAME}_USED)
        msg_blue("find_package:${_USED_PACKAGE_NAME} from package:${PACKAGE_NAME}")
        find_package(${ARGV})

        msg_blue("include ${_USED_PACKAGE_NAME} libs import: ${_USED_PACKAGE_MISC_EXPORT_PATH}")
        include(${_USED_PACKAGE_MISC_EXPORT_PATH})

        set_global_var(${_USED_PACKAGE_NAME}_USED)
    else()
        msg_blue("${_USED_PACKAGE_NAME} skipped - already included")
    endif()
endmacro(use_external_package)

macro(_external_set_defaults)
    if(NOT EXT_BUILD_TYPE)
        set(EXT_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    endif()

    if(NOT EXT_SHARED)
        set(EXT_SHARED ${BUILD_SHARED_LIBS})
    endif()

    if(NOT EXT_VERBOSE)
        set(EXT_VERBOSE ${CMAKE_VERBOSE_MAKEFILE})
    endif()
endmacro(_external_set_defaults)

macro(_external_lib_consumer)
    if(NOT EXT_INSTALL_LIB_DIR)
        set(EXT_INSTALL_LIB_DIR lib)
        #msg_blue("${lib_name} USED INSTALL LIB DIR DEFAULT: ${EXT_INSTALL_LIB_DIR}")
    else()
        msg_blue("${lib_name} used non-default INSTALL LIB DIR: ${EXT_INSTALL_LIB_DIR}")
    endif()

    if(NOT EXT_INSTALL_INC_DIR)
        set(EXT_INSTALL_INC_DIR include)
        #msg_blue("${lib_name} USED INSTALL INC DIR DEFAULT: ${EXT_INSTALL_INC_DIR}")
    else()
        msg_blue("${lib_name} used non-default INSTALL INC DIR: ${EXT_INSTALL_INC_DIR}")
    endif()

    set(EXT_PROJ_INSTALL_LIB_DIR ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_LIB_DIR})
    set(EXT_PROJ_INSTALL_INC_DIR ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_INC_DIR})

    if(EXT_LIB_NAMES)
        set(lib_api_tgt_name "${lib_name}_api")
        msg_blue("${lib_name} exporting api: ${lib_api_tgt_name}")
        msg_blue("${lib_name} searching for libs: ${EXT_LIB_NAMES}")
    else()
        set(lib_api_tgt_name "${lib_name}")
        msg_blue("${lib_name} exporting api only")
    endif()

    add_library(${lib_api_tgt_name} INTERFACE)

    add_library(${NAMESPACE_NAME}${lib_api_tgt_name}
        ALIAS ${lib_api_tgt_name}
    )

    set(EXT_INSTALL_TARGETS ${lib_api_tgt_name})

    foreach(lib ${EXT_LIB_NAMES})
        unset(EXT_LIB_LOCATION CACHE)
        msg_yellow("search lib: ${lib}")
        find_library(EXT_LIB_LOCATION
            NAMES
                "${lib}"
            HINTS
                ${EXT_PROJ_INSTALL_LIB_DIR}
        )
        if(NOT EXT_LIB_LOCATION)
            msg_error("LIB ${lib} not found")
        endif()

        set(lib_import_tgt_name "${lib_name}::${lib}")
        set(lib_import_flag_name "_${lib_name}_${lib}_DEFINED")

        # unused because of the IMPORT crash
        # list(APPEND EXT_INSTALL_TARGETS ${lib_import_tgt_name})

        # imported lib target
        if(EXT_SHARED)
            msg_blue("found ${lib} as ${lib_import_tgt_name} SHARED LIB at: ${EXT_LIB_LOCATION}")
            add_library(${lib_import_tgt_name} SHARED IMPORTED GLOBAL)
        else()
            msg_blue("found ${lib} as ${lib_import_tgt_name} STATIC LIB at: ${EXT_LIB_LOCATION}")
            add_library(${lib_import_tgt_name} STATIC IMPORTED GLOBAL)
        endif()

        # create alias with the namespace
        add_library(${NAMESPACE_NAME}${lib_import_tgt_name}
            ALIAS ${lib_import_tgt_name}
        )

        set_property(TARGET ${lib_import_tgt_name}
            PROPERTY IMPORTED_LOCATION
                ${EXT_LIB_LOCATION}
        )
        #target_link_libraries(${lib_api_tgt_name}
        #    INTERFACE
        #        ${lib_import_tgt_name}
        #)

        file(APPEND ${EXT_MISC_EXPORT_PATH}
            "\n# ${lib_import_tgt_name}\n")

        if(EXT_SHARED)
            file(APPEND ${EXT_MISC_EXPORT_PATH}
                "add_library(${lib_import_tgt_name} SHARED IMPORTED GLOBAL)\n")
        else()
            file(APPEND ${EXT_MISC_EXPORT_PATH}
                "add_library(${lib_import_tgt_name} STATIC IMPORTED GLOBAL)\n")
        endif()

        file(APPEND ${EXT_MISC_EXPORT_PATH}
            "    add_library(${NAMESPACE_NAME}${lib_import_tgt_name} ALIAS ${lib_import_tgt_name})\n"
        )
        if("${lib_name}" STREQUAL "${lib}")
            file(APPEND ${EXT_MISC_EXPORT_PATH}
                "    add_library(${NAMESPACE_NAME}${lib} ALIAS ${lib_import_tgt_name})\n"
            )
        endif()
        file(APPEND ${EXT_MISC_EXPORT_PATH}
            "set_property(TARGET ${lib_import_tgt_name} PROPERTY IMPORTED_LOCATION\n    ${EXT_LIB_LOCATION})\n"
        )
        file(APPEND ${EXT_MISC_EXPORT_PATH}
            "target_link_libraries(${lib_import_tgt_name} INTERFACE ${NAMESPACE_NAME}${lib_api_tgt_name})\n")

        # This causes crash in CMake, circumvented by generating $EXT_MISC_EXPORT_PATH
        #install(TARGETS ${lib_import_tgt_name}
        #    EXPORT ${EXPORT_NAME}
        #    #LIBRARY DESTINATION ${EXT_INSTALL_LIB_DIR}
        #    #ARCHIVE DESTINATION ${EXT_INSTALL_LIB_DIR}
        #    DESTINATION ${EXT_INSTALL_LIB_DIR}i
        #)

    endforeach(lib)

    # expose the installed external include files
    msg_blue("${lib_name} exposed include dir: ${EXT_PROJ_INSTALL_INC_DIR}")
    target_include_directories(${lib_api_tgt_name}
        INTERFACE
            ${EXT_PROJ_INSTALL_INC_DIR}
    )

    install(TARGETS ${EXT_INSTALL_TARGETS}
        EXPORT ${EXPORT_NAME}
        DESTINATION ${EXT_INSTALL_LIB_DIR}
    )
    install(EXPORT ${EXPORT_NAME}
        NAMESPACE ${NAMESPACE_NAME}
        DESTINATION ${PACKAGE_NAME}
        FILE ${EXPORT_FILE}
    )
    export(EXPORT ${EXPORT_NAME}
        NAMESPACE ${NAMESPACE_NAME}
    )

    msg_green("${lib_name} exported")

endmacro(_external_lib_consumer)

macro(_external_cmake_lib_producer)
    set(EXT_PROJ_NAME ${lib_name}-project) # symbolic name for external project
    # declare new external project
    ExternalProject_Add(
        ${EXT_PROJ_NAME}
        SOURCE_DIR
            ${CMAKE_CURRENT_SOURCE_DIR}/${EXT_SRC_SUBDIR}
        BINARY_DIR
            ${CMAKE_CURRENT_BINARY_DIR}
        INSTALL_DIR
            ${EXT_PROJ_INSTALL_DIR}
        CMAKE_ARGS
            -DCMAKE_BUILD_TYPE:STRING=${EXT_BUILD_TYPE}
            -DBUILD_SHARED_LIBS:BOOL=${EXT_SHARED}
            -DCMAKE_VERBOSE_MAKEFILE:BOOL=${EXT_VERBOSE}
            -DCMAKE_INSTALL_PREFIX=${EXT_PROJ_INSTALL_DIR}
        UPDATE_COMMAND ""
        PATCH_COMMAND ""
        TEST_COMMAND ""
        STEP_TARGETS build install
    )
    add_dependencies(${EXT_PACKAGE_TARGET} ${EXT_PROJ_NAME}-install)

    msg_green("Added external project ${EXT_PROJ_NAME}")
    msg_blue("${lib_name} BUILD_TYPE:${EXT_BUILD_TYPE} SHARED:${EXT_SHARED} VERBOSE:${EXT_VERBOSE}")
    ExternalProject_Get_Property(${EXT_PROJ_NAME} SOURCE_DIR BINARY_DIR INSTALL_DIR)
    msg_blue("${lib_name} SOURCE: ${SOURCE_DIR}")
    msg_blue("${lib_name} BINARY: ${BINARY_DIR}")
    msg_blue("${lib_name} INSTALL: ${INSTALL_DIR}")

    # install misc files
    if(EXT_FILES)
        msg_blue("Misc files install: ${EXT_FILES}")
        install(
            FILES ${EXT_FILES}
            DESTINATION ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_FILES_DIR}
        )
    endif()
endmacro(_external_cmake_lib_producer)

macro(_external_api_producer)
    if(EXT_API_DIR)
        set(API_DIR ${EXT_API_DIR})
    endif()

    foreach(hdr ${EXT_API_HEADERS})
        list(APPEND RELATIVE_API_HEADERS
            "${API_DIR}/${hdr}"
        )
    endforeach(hdr)

    if(NOT EXT_INSTALL_INC_DIR)
        set(EXT_INSTALL_INC_DIR include)
        msg_blue("${lib_name} INSTALL INC DIR (DEFAULT): ${EXT_INSTALL_INC_DIR}")
    else()
        msg_blue("${lib_name} INSTALL INC DIR: ${EXT_INSTALL_INC_DIR}")
    endif()

    msg_green("Added external api lib ${lib_name}")
    msg_blue("${lib_name} SOURCE: ${CMAKE_CURRENT_SOURCE_DIR}/${API_DIR}")
    msg_blue("${lib_name} INSTALL: ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_INC_DIR}")

    # install API headers
    install(
        FILES ${RELATIVE_API_HEADERS}
        DESTINATION ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_INC_DIR}
    )
    # install misc files
    if(EXT_FILES)
        msg_blue("Misc files install: ${EXT_FILES}")
        install(
            FILES ${EXT_FILES}
            DESTINATION ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_FILES_DIR}
        )
    endif()
endmacro(_external_api_producer)

macro(_external_api_consumer)
    if(NOT EXT_INSTALL_INC_DIR)
        set(EXT_INSTALL_INC_DIR include)
        msg_blue("${lib_name} INSTALL INC DIR (DEFAULT): ${EXT_INSTALL_INC_DIR}")
    else()
        msg_blue("${lib_name} INSTALL INC DIR: ${EXT_INSTALL_INC_DIR}")
    endif()

    set(lib_tgt_name "${lib_name}")
    msg_blue("${lib_tgt_name} external API LIB: ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_INC_DIR}")
    add_library(${lib_tgt_name} INTERFACE IMPORTED GLOBAL)

    target_include_directories(${lib_tgt_name}
        INTERFACE
            ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_INC_DIR}
    )
    # create alias with the namespace
    add_library(${NAMESPACE_NAME}${lib_tgt_name}
        ALIAS ${lib_tgt_name}
    )

    msg_green("Added external API LIB ${lib_name}")
endmacro(_external_api_consumer)

function(define_external_api_lib lib_name)
    # parse arguments
    set(args_options)
    set(args_single API_DIR INSTALL_INC_DIR)
    set(args_multi API_HEADERS FILES)

    cmake_parse_arguments("EXT" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    msg_yellow("\n${lib_name} external_api_lib")

    if(EXT_UNPARSED)
        message("Unparsed arguments for define_external_api_lib(${lib_name}: ${EXT_UNPARSED}")
    endif()

    # declare new external project
    project(${lib_name})

    SET(EXT_PROJ_INSTALL_DIR ${EXT_PACKAGE_INSTALL_PREFIX}/${lib_name})

    if(BUILD_3RD_PARTY)
        _external_api_producer()
    else()
#        _external_api_consumer()
         _external_lib_consumer()
    endif()

endfunction(define_external_api_lib)

function(define_external_cmake_lib lib_name)
    # parse arguments
    set(args_options SHARED VERBOSE)
    set(args_single SRC_SUBDIR INSTALL_LIB_DIR INSTALL_INC_DIR BUILD_TYPE)
    set(args_multi LIB_NAMES FILES)

    cmake_parse_arguments("EXT" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    msg_yellow("\n${lib_name} external_cmake_lib")

    if(EXT_UNPARSED)
        message("Unparsed arguments for define_external_cmake_lib(${lib_name}: ${EXT_UNPARSED}")
    endif()

    _external_set_defaults()

    # declare new external project
    project(${lib_name})

    SET(EXT_PROJ_INSTALL_DIR ${EXT_PACKAGE_INSTALL_PREFIX}/${lib_name})

    if(BUILD_3RD_PARTY)
        _external_cmake_lib_producer()
    else()
        _external_lib_consumer()
    endif()

endfunction(define_external_cmake_lib)

macro(_external_auto_make_lib_producer)
    set(EXT_PROJ_NAME ${lib_name}-project) # symbolic name for external project
    if(NOT CMAKE_VERBOSE_MAKEFILE)
        set(EXT_AUTOMAKE_CONFIGURE_QUIET --quiet)
    endif()

    # declare new external project
    ExternalProject_Add(
        ${EXT_PROJ_NAME}
        SOURCE_DIR
            ${CMAKE_CURRENT_SOURCE_DIR}/${EXT_SRC_SUBDIR}
        BINARY_DIR
            ${CMAKE_CURRENT_BINARY_DIR}
        INSTALL_DIR
            ${EXT_PROJ_INSTALL_DIR}
        CONFIGURE_COMMAND
            ${CMAKE_CURRENT_SOURCE_DIR}/${EXT_SRC_SUBDIR}/configure --prefix ${EXT_PROJ_INSTALL_DIR} ${EXT_AUTOMAKE_CONFIGURE_QUIET}
        BUILD_COMMAND
            $(MAKE)
        INSTALL_COMMAND
            $(MAKE) install -j 1
        PREFIX=${EXT_PROJ_INSTALL_DIR}
        UPDATE_COMMAND ""
        PATCH_COMMAND ""
        TEST_COMMAND ""
        STEP_TARGETS configure build install
    )
    add_dependencies(${EXT_PACKAGE_TARGET} ${EXT_PROJ_NAME}-install)

    msg_green("Added external autotools Makefile project ${EXT_PROJ_NAME}")

    ExternalProject_Get_Property(${EXT_PROJ_NAME} SOURCE_DIR BINARY_DIR INSTALL_DIR)
    msg_blue("${lib_name} SOURCE: ${SOURCE_DIR}")
    msg_blue("${lib_name} BINARY: ${BINARY_DIR}")
    msg_blue("${lib_name} INSTALL: ${INSTALL_DIR}")

    # install API headers
    install(
        FILES ${RELATIVE_API_HEADERS}
        DESTINATION ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_INC_DIR}
    )
    # install misc files
    if(EXT_FILES)
        msg_blue("Misc files install: ${EXT_FILES}")
        install(
            FILES ${EXT_FILES}
            DESTINATION ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_FILES_DIR}
        )
    endif()
endmacro(_external_auto_make_lib_producer)

function(define_external_auto_make_lib lib_name)
    # parse arguments
    set(args_options VERBOSE)
    set(args_single SRC_SUBDIR INSTALL_LIB_DIR INSTALL_INC_DIR BUILD_TYPE)
    set(args_multi LIB_NAMES FILES)

    cmake_parse_arguments("EXT" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    msg_yellow("\n${lib_name} external_auto_make_lib")

    if(EXT_UNPARSED)
        message("Unparsed arguments for define_external_auto_make_lib(${lib_name}: ${EXT_UNPARSED}")
    endif()

    # declare new external project
    project(${lib_name})

    SET(EXT_PROJ_INSTALL_DIR ${EXT_PACKAGE_INSTALL_PREFIX}/${lib_name})

    if(BUILD_3RD_PARTY)
        _external_auto_make_lib_producer()
    else()
        _external_lib_consumer()
    endif()

endfunction(define_external_auto_make_lib)

macro(_external_plain_make_lib_producer)
    set(EXT_PROJ_NAME ${lib_name}-project) # symbolic name for external project
    # declare new external project
    set(EXT_MAKE_ARGS
        ${EXT_MAKE_BUILD_ARG}=${CMAKE_CURRENT_BINARY_DIR} ${EXT_MAKE_INSTALL_ARG}=${EXT_PROJ_INSTALL_DIR})
    set(EXT_PROJ_SRC_DIR
        ${CMAKE_CURRENT_SOURCE_DIR}/${EXT_SRC_SUBDIR})
    ExternalProject_Add(
        ${EXT_PROJ_NAME}
        SOURCE_DIR
            ${EXT_PROJ_SRC_DIR}
        BINARY_DIR
            ${CMAKE_CURRENT_BINARY_DIR}
        INSTALL_DIR
            ${EXT_PROJ_INSTALL_DIR}
        BUILD_COMMAND
            $(MAKE) -C ${EXT_PROJ_SRC_DIR} -f ${EXT_MAKEFILE_NAME} ${EXT_MAKE_ARGS} ${EXT_MAKE_TARGET}
        INSTALL_COMMAND
            $(MAKE) -C ${EXT_PROJ_SRC_DIR} -f ${EXT_MAKEFILE_NAME} ${EXT_MAKE_ARGS} install
        CONFIGURE_COMMAND ""
        UPDATE_COMMAND ""
        PATCH_COMMAND ""
        TEST_COMMAND ""
        STEP_TARGETS build install
    )
    add_dependencies(${EXT_PACKAGE_TARGET} ${EXT_PROJ_NAME}-install)

    msg_green("Added external plain Makefile project ${EXT_PROJ_NAME}")

    foreach(proj_dep ${EXT_DEPENDS_ON})
        ExternalProject_Add_StepDependencies(${EXT_PROJ_NAME} build ${proj_dep}-project)
        msg_yellow("${EXT_PROJ_NAME} depends on: ${proj_dep}-project")
    endforeach(proj_dep)

    msg_blue("${lib_name} SOURCE: ${EXT_PROJ_SRC_DIR}")
    msg_blue("${lib_name} BINARY: ${CMAKE_CURRENT_BINARY_DIR}")
    msg_blue("${lib_name} INSTALL: ${EXT_PROJ_INSTALL_DIR}")

    # install misc files
    if(EXT_FILES)
        msg_blue("Misc files install: ${EXT_FILES}")
        install(
            FILES ${EXT_FILES}
            DESTINATION ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_FILES_DIR}
        )
    endif()
endmacro(_external_plain_make_lib_producer)

function(define_external_plain_make_lib lib_name)
    # parse arguments
    set(args_options SHARED VERBOSE)
    set(args_single
            SRC_SUBDIR MAKEFILE_NAME MAKE_BUILD_ARG MAKE_INSTALL_ARG
            MAKE_TARGET INSTALL_LIB_DIR INSTALL_INC_DIR BUILD_TYPE)
    set(args_multi LIB_NAMES DEPENDS_ON FILES)

    cmake_parse_arguments("EXT" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    msg_yellow("\n${lib_name} external_plain_make_lib")

    if(EXT_UNPARSED)
        message("Unparsed arguments for define_external_auto_make_lib(${lib_name}: ${EXT_UNPARSED}")
    endif()

    _external_set_defaults()

    # declare new external project
    project(${lib_name})

    SET(EXT_PROJ_INSTALL_DIR ${EXT_PACKAGE_INSTALL_PREFIX}/${lib_name})

    if(BUILD_3RD_PARTY)
        _external_plain_make_lib_producer()
    else()
        _external_lib_consumer()
    endif()

endfunction(define_external_plain_make_lib)

macro(_external_kernel_module_producer)
    set(EXT_PROJ_NAME ${EXT_MODULE_PROJ_NAME}-project) # symbolic name for external project
    # declare new external project
    set(EXT_PROJ_BUILD_DIR
        ${CMAKE_CURRENT_BINARY_DIR})
    set(EXT_PROJ_SRC_DIR
        ${EXT_PROJ_BUILD_DIR}/${EXT_SRC_SUBDIR})

    ExternalProject_Add(
        ${EXT_PROJ_NAME}
        DOWNLOAD_COMMAND
            rsync -r --inplace ${CMAKE_CURRENT_SOURCE_DIR}/ ${EXT_PROJ_BUILD_DIR}/
        SOURCE_DIR
            ${EXT_PROJ_SRC_DIR}
        BINARY_DIR
            ${EXT_PROJ_SRC_DIR}
        INSTALL_DIR
            ${EXT_PROJ_INSTALL_DIR}
        BUILD_COMMAND
            KDIR=${KERNEL_DIR} $(MAKE) -C ${EXT_PROJ_SRC_DIR} -f ${EXT_MAKEFILE_NAME} ${EXT_MAKE_ARGS} ${EXT_MAKE_TARGET}
        INSTALL_COMMAND
            find ${EXT_PROJ_SRC_DIR} -name *.ko | xargs -I{} cp {} ${EXT_PROJ_INSTALL_DIR}
        CONFIGURE_COMMAND ""
        UPDATE_COMMAND ""
        PATCH_COMMAND ""
        TEST_COMMAND ""
        STEP_TARGETS build install
    )
    add_dependencies(${EXT_PACKAGE_TARGET} ${EXT_PROJ_NAME}-install)

    msg_green("Added external kernel module project ${EXT_PROJ_NAME}")

    foreach(proj_dep ${EXT_DEPENDS_ON})
        ExternalProject_Add_StepDependencies(${EXT_PROJ_NAME} build ${proj_dep}-modules-project)
        msg_yellow("${EXT_PROJ_NAME} depends on: ${proj_dep}-modules-project")
    endforeach(proj_dep)

    msg_blue("${lib_name} SOURCE: ${EXT_PROJ_SRC_DIR}")
    msg_blue("${lib_name} BINARY: ${CMAKE_CURRENT_BINARY_DIR}")
    msg_blue("${lib_name} INSTALL: ${EXT_PROJ_INSTALL_DIR}")

    # install misc files
    if(EXT_FILES)
        msg_blue("Misc files install: ${EXT_FILES}")
        install(
            FILES ${EXT_FILES}
            DESTINATION ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_FILES_DIR}
        )
    endif()

    # install executables
    if(EXT_PROGRAMS)
        msg_blue("Misc executables install: ${EXT_PROGRAMS}")
        install(
            PROGRAMS ${EXT_PROGRAMS}
            DESTINATION ${EXT_PROJ_INSTALL_DIR}/${EXT_INSTALL_FILES_DIR}
        )
    endif()
endmacro(_external_kernel_module_producer)

function(define_external_kernel_module lib_name)
    # parse arguments
    set(args_options VERBOSE)
    set(args_single SRC_SUBDIR MAKEFILE_NAME MAKE_TARGET)
    set(args_multi DEPENDS_ON FILES PROGRAMS)

    cmake_parse_arguments("EXT" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    msg_yellow("\n${lib_name} external_kernel_module")

    if(EXT_UNPARSED)
        msg_red("Unparsed arguments for define_external_kernel_module(${lib_name}: ${EXT_UNPARSED}")
        return()
    endif()

    if(NOT BUILD_3RD_PARTY)
        msg_green("${lib_name} - nothing to export")
        return()
    endif()

    # declare new external project
    set(EXT_MODULE_PROJ_NAME ${lib_name}-modules)
    project(${EXT_MODULE_PROJ_NAME})
    add_custom_target(${EXT_MODULE_PROJ_NAME})

    SET(EXT_PROJ_INSTALL_DIR ${EXT_PACKAGE_INSTALL_PREFIX}/modules/${lib_name})

    _external_kernel_module_producer()

endfunction(define_external_kernel_module)

function(define_external_py_ext lib_name)
    # parse arguments
    set(args_options )
    set(args_single SRC_DIR LIB_DIR)
    set(args_multi SOURCES SYS_LIBS INC_DIRS)

    cmake_parse_arguments("PY_EXT" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    if(PY_EXT_UNPARSED)
        message("Unparsed arguments for define_py_ext(${lib_name}: ${PY_EXT_UNPARSED}")
    endif()

    msg_yellow("\n${lib_name} external_py_ext")
    if(BUILD_3RD_PARTY)
        define_py_ext(${ARGV})
    else()
        msg_green("${lib_name} - nothing to export")
    endif()

endfunction(define_external_py_ext)

endif (NOT _EXTERNAL_CMAKE_INCLUDED)
