# options.cmake
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

if (NOT _OPTIONS_CMAKE_INCLUDED)
set(_OPTIONS_CMAKE_INCLUDED YES)

# General unconditional Options
set(CMAKE_LEGACY_CYGWIN_WIN32 0) # for Windows IDEs

# Boolean User Options
option(BUILD_SHARED "Build shared libraries" OFF)
option(VERBOSE_MAKE "Verbose makefile" OFF)

# String User Options
set(BUILD_TYPE "Debug" CACHE STRING "Build type: Debug, Release")

msg_green("Options:")
msg_blue("BUILD_SHARED=${BUILD_SHARED}")
msg_blue("VERBOSE_MAKE=${VERBOSE_MAKE}")
msg_blue("BUILD_TYPE=${BUILD_TYPE}")
msg_green("---")

if (BUILD_SHARED)
    set(BUILD_SHARED_LIBS ON)
else ()
    set(BUILD_SHARED_LIBS OFF)
endif ()

if (VERBOSE_MAKE)
    set(CMAKE_VERBOSE_MAKEFILE ON)
    set(CMAKE_RULE_MESSAGES ON)
else ()
    set(CMAKE_VERBOSE_MAKEFILE OFF)
    set(CMAKE_RULE_MESSAGES OFF)
endif ()

if ("${BUILD_TYPE}" STREQUAL "Debug" OR "${BUILD_TYPE}" STREQUAL "Release")
    set(CMAKE_BUILD_TYPE ${BUILD_TYPE})
else ()
    msg_error("Build type: ${BUILD_TYPE} unsupported")
endif ()

endif(NOT _OPTIONS_CMAKE_INCLUDED)
