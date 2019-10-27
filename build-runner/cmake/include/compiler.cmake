# compiler.cmake
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

if (NOT _MESSAGES_CMAKE_INCLUDED)
    include(${INC_CMAKE_DIR}/messages.cmake)
endif()

if (NOT _COMPILER_CMAKE_INCLUDED)
set(_COMPILER_CMAKE_INCLUDED YES)

# set common C/C++ compile definitions
set(COMPILER_DEFS "-D_GNU_SOURCE -D__USE_POSIX")
string(APPEND COMPILER_DEFS " -D_LITTLE_ENDIAN")
string(APPEND COMPILER_DEFS " -D_REENTRANT")
string(APPEND COMPILER_DEFS " -D__USE_LARGEFILE64 -D_FILE_OFFSET_BITS=64")

# set C++ compile options
set(CMAKE_CXX_FLAGS ${COMPILER_DEFS})
string(APPEND CMAKE_CXX_FLAGS " -std=c++14")
string(APPEND CMAKE_CXX_FLAGS " -Wall")
string(APPEND CMAKE_CXX_FLAGS " -Werror")
string(APPEND CMAKE_CXX_FLAGS " -Wextra")
string(APPEND CMAKE_CXX_FLAGS " -Wcomment")
string(APPEND CMAKE_CXX_FLAGS " -Wpointer-arith")
string(APPEND CMAKE_CXX_FLAGS " -Wcast-align")
string(APPEND CMAKE_CXX_FLAGS " -Wconversion")
string(APPEND CMAKE_CXX_FLAGS " -Wshadow")

# set C compile options
set(CMAKE_C_FLAGS ${COMPILER_DEFS})
string(APPEND CMAKE_C_FLAGS " -std=c99")
string(APPEND CMAKE_C_FLAGS " -Wall")
string(APPEND CMAKE_C_FLAGS " -Wno-endif-labels")
string(APPEND CMAKE_C_FLAGS " -Wformat")
string(APPEND CMAKE_C_FLAGS " -Wno-multichar")
string(APPEND CMAKE_C_FLAGS " -Wunused")
string(APPEND CMAKE_C_FLAGS " -Wno-parentheses")

msg_red("Build type: ${CMAKE_BUILD_TYPE}")
if ("${CMAKE_BUILD_TYPE}" MATCHES "Debug*")
    string(APPEND CMAKE_C_FLAGS " -DDEBUG -g -O3")
    string(APPEND CMAKE_CXX_FLAGS " -DDEBUG -g -O3")
else ()
    string(APPEND CMAKE_C_FLAGS " -DNDEBUG -O3")
    string(APPEND CMAKE_CXX_FLAGS " -DNDEBUG -O3")
endif ()

endif(NOT _COMPILER_CMAKE_INCLUDED)
