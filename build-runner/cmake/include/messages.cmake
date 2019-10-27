# messages.cmake
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
set(_MESSAGES_CMAKE_INCLUDED YES)

# printing in colors
if (NOT WIN32)
    string(ASCII 27 Esc)
    set(Reset   "${Esc}[m"  )
    set(Red     "${Esc}[31m")
    set(Blue    "${Esc}[34m")
    set(Green   "${Esc}[32m")
    set(Yellow  "${Esc}[33m")
endif()

function(msg_colored msg_str color)
    message("${color}${msg_str}${Reset}")
endfunction()

macro(msg_red msg_str)
    msg_colored("${msg_str}" ${Red})
endmacro()

macro(msg_blue msg_str)
    msg_colored("${msg_str}" ${Blue})
endmacro()

macro(msg_green msg_str)
    msg_colored("${msg_str}" ${Green})
endmacro()

macro(msg_yellow msg_str)
    msg_colored("${msg_str}" ${Yellow})
endmacro()

macro(msg_error msg_str)
    message(FATAL_ERROR "${Red}${msg_str}${Reset}")
endmacro()

endif(NOT _MESSAGES_CMAKE_INCLUDED)
