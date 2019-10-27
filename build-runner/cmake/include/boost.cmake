# boost.cmake
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

if (NOT _BOOST_CMAKE_INCLUDED)
set(_BOOST_CMAKE_INCLUDED YES)

find_package(Boost
    1.66 REQUIRED
    COMPONENTS
        thread system serialization filesystem iostreams chrono timer regex date_time
)

msg_blue("BOOST_LIB_DIR: ${Boost_LIBRARY_DIRS}")
msg_blue("BOOST_INC_DIR: ${Boost_INCLUDE_DIRS}")
msg_blue("BOOST_LIBS:    ${Boost_LIBRARIES}")

include_directories("${Boost_INCLUDE_DIRS}")
#ADD_DEFINITIONS(-DBOOST_LOG_DYN_LINK)
#set(Boost_USE_MULTITHREADED ON)

endif(NOT _BOOST_CMAKE_INCLUDED)
