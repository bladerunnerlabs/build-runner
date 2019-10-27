# packages.cmake
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

if (NOT _MESSAGES_CMAKE_INCLUDED)
    include(${INC_CMAKE_DIR}/messages.cmake)
endif()

if (NOT _PACKAGES_CMAKE_INCLUDED)
set(_PACKAGES_CMAKE_INCLUDED YES)

macro(define_package name)
    # parse arguments
    set(args_options)
    set(args_single)
    set(args_multi FILES)

    cmake_parse_arguments("PACKAGE" "${args_options}" "${args_single}" "${args_multi}" ${ARGN})

    if(PACKAGE_UNPARSED)
        message("Unparsed arguments for define_package(${name}: ${PACKAGE_UNPARSED}")
    endif()

    if(NOT BUILD_ROOT_DIR)
        message("BUILD_ROOT_DIR not set")
    endif()
    set(INSTALL_PATH ${BUILD_ROOT_DIR}/${CMAKE_PREFIX_PATH})

    msg_red("PROJECT: ${CMAKE_PROJECT_NAME}")
    msg_red("CMAKE_PREFIX_PATH (install path): ${CMAKE_PREFIX_PATH}")
    msg_red("CMAKE_MODULE_PATH (extra package search): ${CMAKE_MODULE_PATH}")

    set(PACKAGE_NAME ${name})

    set(NAMESPACE_NAME ${PACKAGE_NAME}::)
    set(EXPORT_NAME ${PACKAGE_NAME}-export)
    set(EXPORT_FILE ${PACKAGE_NAME}-config.cmake)

    # package root installation dir
    set(PACKAGE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/${PACKAGE_NAME})

    if(PACKAGE_FILES)
        msg_yellow("\n${name} package, files to install: ${PACKAGE_FILES}")
        install(FILES ${PACKAGE_FILES}
            DESTINATION ${PACKAGE_INSTALL_PREFIX}
        )
    endif()

    # set default sub-directories
    set(API_DIR ext_api) # Default External (public) API subdirectory
    set(SRC_DIR sources) # Default Sources subdirectory
endmacro()

macro(use_package)
    set(_USED_PACKAGE_NAME ${ARGV0})
    msg_green("use package: ${_USED_PACKAGE_NAME}")
    if(NOT SINGLE_TREE)
        if(NOT "${_USED_PACKAGE_NAME}" STREQUAL "${PACKAGE_NAME}")
            if(NOT ${_USED_PACKAGE_NAME}_FOUND)
                msg_blue("find_package:${_USED_PACKAGE_NAME} from package:${PACKAGE_NAME}")
                find_package(${ARGV})
            else()
                msg_blue("find_package:${_USED_PACKAGE_NAME} skipped - already included")
            endif()
        else ()
            msg_blue("find_package( ${ARGV} ) skipped - inside package: ${PACKAGE_NAME}")
        endif()
    else()
        msg_blue("find_package( ${ARGV} ) skipped - single tree setup")
    endif()

    set(_USED_PACKAGE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/${_USED_PACKAGE_NAME})
endmacro()

endif(NOT _PACKAGES_CMAKE_INCLUDED)
