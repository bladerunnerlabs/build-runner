#!/bin/bash

SCRIPT_NAME=`basename $0`

if [[ "${TERM}" = xterm* ]]; then
    YELLOW="\033[93m"
    GREEN="\033[92m"
    BLUE="\033[94m"
    RED="\033[91m"
    NORM="\033[0m"
elif [[ "${TERM}" = linux* ]]; then
    YELLOW="\033[33;1m"
    GREEN="\033[32;1m"
    BLUE="\033[34;1m"
    RED="\033[31;1m"
    NORM="\033[0m"
fi

function msg_blue()
{
    echo -e "${BLUE}$@${NORM}"
}

function msg_yellow()
{
    echo -e "${YELLOW}$@${NORM}"
}

function msg_red()
{
    echo -e "${RED}$@${NORM}"
}

function msg_green()
{
    echo -e "${GREEN}$@${NORM}"
}

function usage()
{
    echo -e "Usage: ${SCRIPT_NAME} [options]"
    echo -e "   ${BLUE}-f|--file <path>/cmake-<version>-Linux-x86_64.tar.gz${NORM} : install from a tar file"
    echo -e "   ${BLUE}-w|--wget <version>${NORM} : retrieve the tar file using wget"
    echo -e "   ${BLUE}-D|--delete${NORM} : delete the tar file after installation"
    echo -e "   ${BLUE}-C|--clean${NORM} : only clean-up current CMake installation"
    echo -e "Examples:"
    echo -e "   ./${SCRIPT_NAME} -f ../cmake-3.12.4-Linux-x86_64.tar.gz"
    echo -e "   ./${SCRIPT_NAME} -w 3.12.4 -D"
    echo -e "   ./${SCRIPT_NAME} -C"
    exit 1
}

function bad_format()
{
    echo -e "${RED}$@${NORM} does not follow the expected format"
    usage
}

function clean_apt_get()
{
    msg_yellow "Removing cmake apt package ..."
    apt-get purge -y cmake
}

function clean_usr_local()
{
    msg_yellow "Cleaning /usr/local ..."
    rm -rfv /usr/local/bin/{cmake,cpack,ccmake,cmake-gui,ctest} \
            /usr/local/doc/cmake \
            /usr/local/man1/{ccmake.1,cmake.1,cmake-gui.1,cpack.1,ctest.1} \
            /usr/local/man7/cmake-* \
            /usr/local/share/cmake-*
}

function clean_usr_bin()
{
    msg_yellow "Cleaning /usr/bin ..."
    rm -rfv /usr/bin/{cmake,cpack,ccmake,cmake-gui,ctest}
}

function clean_old_inst()
{
    msg_blue "Clean previous cmake installations..."
    clean_apt_get
    clean_usr_bin
    clean_usr_local
    msg_blue "Clean done"
}

function parse_args()
{
    options=$(getopt \
        -o "f:w:CDh" \
        -l "file:,wget:,clean,delete,help" \
        -- "$@")
    if [ $? -ne 0 ]; then
        msg_red "${SCRIPT_NAME}: failed to parse arguments\n"
        usage 1
    fi

    eval set -- ${options}

    while [ $# -gt 1 ]; do
        case $1 in
            -f|--file) FILE_PATH=$2; shift; ;;
            -w|--wget) CMAKE_VER=$2; shift; ;;
            -C|--clean) CLEAN_ONLY=true; ;;
            -D|--delete) DELETE_FILE=true; ;;
            -h|--help) usage 0; ;;
            # default options
            (--) shift; break ;;
            (-*) msg_red "${SCRIPT_NAME}: error - unrecognized option $1\n" 1>&2;
                 usage 1; ;;
            (*) break ;;
        esac
        shift
    done
}

if [[ -z "$1" ]]; then
    usage
fi

parse_args "$@"

if [[ -n "${FILE_PATH}" && -n "${CMAKE_VER}" ]]; then
    msg_red "-f and -w can't be supplied together"
    usage
fi

if [[ "${CLEAN_ONLY}" == true ]]; then
    clean_old_inst
    exit 0
fi

if [[ -n "${FILE_PATH}" ]]; then
    FILE_PATH=`readlink -f ${FILE_PATH}`
    if [[ ! -f "${FILE_PATH}" ]]; then
        msg_red "${FILE_PATH} does not exist"
        usage
    fi
    FILE_NAME=`basename ${FILE_PATH}`

    CMAKE_VER_1=${FILE_NAME%%-Linux-x86_64.tar.gz*}
    if [[ "${CMAKE_VER_1}" == ${FILE_NAME} ]]; then
        bad_format "${FILE_NAME}"
    fi

    CMAKE_VER=${CMAKE_VER_1##cmake-}
    if [[ "${CMAKE_VER}" == ${CMAKE_VER_1} ]]; then
        bad_format "${FILE_NAME}"
    fi

    if [[ -z "${CMAKE_VER}" ]]; then
        bad_format "${FILE_NAME}"
    fi

elif [[ -n "${CMAKE_VER}" ]]; then
    FILE_NAME="cmake-${CMAKE_VER}-Linux-x86_64.tar.gz"
    FILE_PATH="${PWD}/${FILE_NAME}"
    WGET_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/${FILE_NAME}"
    msg_blue "wget ${WGET_URL} ..."
    wget ${WGET_URL} || exit 1
    msg_blue "wget done"
else
    usage
fi

msg_green "File: ${FILE_PATH}"
msg_green "Version: ${CMAKE_VER}"

clean_old_inst

msg_blue "Unpacking the tar file..."
pushd "/usr/local"
tar -xzvf ${FILE_PATH} --strip 1 || exit 1
popd

if [[ "${DELETE_FILE}" == true ]]; then
    msg_blue "Delete ${FILE_PATH} ..."
    rm -fv ${FILE_PATH}
fi

msg_green "Done"
