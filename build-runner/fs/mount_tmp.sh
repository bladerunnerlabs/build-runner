#!/bin/bash

DEF_FS_SIZE="4000"
DEF_FS_MNT_DIR="./tmp-mount"

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
    echo -e "Usage: ${BLUE}${SCRIPT_NAME} [options] -- [make-options]${NORM}\n"
    echo -e "options:"
    echo -e "${BLUE}-s | --size [size-MB]${NORM}: size of mount in MB [${DEF_FS_SIZE}]"
    echo -e "${BLUE}-d | --dir [mount-dir]${NORM}:  mount dir nameB [${DEF_FS_MNT_DIR}]"
    echo -e "${BLUE}-V | --verbose${NORM}: produce verbose output, [off]"
    echo -e "${BLUE}-h | --help   ${NORM}: print the help message"
    exit $1
}

function parse_args()
{
    options=$(getopt \
        -o "s:d:Vh" \
        -l "size:,dir:,verbose,help" \
        -- "$@")
    if [ $? -ne 0 ]; then
        msg_red "${SCRIPT_NAME}: failed to parse arguments\n"
        usage 1
    fi

    eval set -- ${options}

    while [ $# -gt 1 ]; do
        case $1 in
            -s|--size) CMD_FS_SIZE=$2; shift; ;;
            -d|--dir) CMD_FS_MNT_DIR=$2; shift; ;;

            -V|--verbose) VERBOSE=true; ;;
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

# parse command line arguments
parse_args $@

FS_SIZE="${CMD_FS_SIZE:-${DEF_FS_SIZE}}m"
FS_MNT_DIR="${CMD_FS_MNT_DIR:-${DEF_FS_MNT_DIR}}"

msg_blue "sz:${FS_SIZE} mnt.dir:${FS_MNT_DIR}"
if [[ -d ${FS_MNT_DIR} ]]; then
    [[ "${VERBOSE}" == true ]] && msg_yellow "mnt.dir exists; check is mounted: mountpoint ${FS_MNT_DIR} -q"
    mountpoint ${FS_MNT_DIR} -q && { msg_red "${FS_MNT_DIR} already mounted"; exit 1; }
    [[ "${VERBOSE}" == true ]] && msg_green "not mounted"
else
    [[ "${VERBOSE}" == true ]] && msg_yellow "Creating dir:${FS_MNT_DIR}"
    mkdir -p ${FS_MNT_DIR} || exit 1
    [[ "${VERBOSE}" == true ]] && msg_green "Done"
fi
[[ "${VERBOSE}" == true ]] && msg_yellow "Mounting tmpfs on dir:${FS_MNT_DIR}"
mount -t tmpfs -o size=${FS_SIZE} tmpfs ${FS_MNT_DIR} || { msg_red "mount failed"; exit 1; }
[[ "${VERBOSE}" == true ]] && msg_green "Done"

