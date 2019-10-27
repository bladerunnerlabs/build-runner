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

function msg_verbose()
{
    if [[ "${VERBOSE}" == true ]]; then
        echo -e "$@"
    fi
}

function err_exit()
{
    if [[ -n "$*" ]]; then
        msg_red "$*"
    fi
    exit 1
}

DEF_UT_DIR='.'
DEF_BLACKLIST_FNAME='blacklist.txt'

function usage()
{
    echo -e "Usage: ${BLUE}${SCRIPT_NAME} [options]${NORM}\n"
    echo -e "options:"
    echo -e "${BLUE}-d | --dir [dir-path]${NORM}: path to ut directory [${DEF_UT_DIR}]"
    echo -e "${BLUE}-b | --blacklist [file-name]${NORM}: blacklist file name, in ut directory [${DEF_BLACKLIST_FNAME}]"
    echo -e "${BLUE}-D | --dry ${NORM}: perform dry run, only print processed lines [off]"
    echo -e "${BLUE}-V | --verbose${NORM}: produce verbose output, [off]"
    echo -e "${BLUE}-h | --help   ${NORM}: print the help message"
    exit $1
}

function parse_args()
{
    options=$(getopt \
        -o "d:b:DVh" \
        -l "dir:,blacklist:,dry,verbose,help" \
        -- "$@")
    if [ $? -ne 0 ]; then
        msg_red "${SCRIPT_NAME}: failed to parse arguments\n"
        usage 1
    fi

    eval set -- ${options}

    while [ $# -gt 1 ]; do
        case $1 in
            -d|--dir) CMD_UT_DIR=$2; shift; ;;
            -b|--blacklist) CMD_BLACKLIST_FNAME=$2; shift; ;;
            -D|--dry) DRY_RUN=true; ;;
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

args="$@"
parse_args ${args}

UT_DIR="${CMD_UT_DIR:-${DEF_UT_DIR}}"
BLACKLIST_FNAME="${CMD_BLACKLIST_FNAME:-${DEF_BLACKLIST_FNAME}}"

function log_exec()
{
    local cmd_arr=("$*")
    msg_blue "$*"
    $* || err_exit "${cmd_arr[0]} failed"
}

function get_dir_path()
{
    local dir_name="$1"
    readlink -e ${dir_name} || err_exit "${dir_name} not found"
}

function trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "${var}"
}

function list_from_file()
{
    local fname="$1"
    local cleaned=`sed '/^[[:blank:]]*#/d;s/#.*//' ${fname} | dos2unix`
    local line
    for line in ${cleaned}; do
        [[ -n "`trim ${line}`" ]] && echo "${line}"
    done
}

function in_blacklist()
{
    local fname="$1"
    local b
    for b in ${black_list[*]}; do
        if [ ${fname} == ${b} ]; then
            return 0
        fi
    done
    return 1
}

msg_blue "UT dir: ${UT_DIR}"
UT_DIR_PATH=`get_dir_path ${UT_DIR}`
[[ "${UT_DIR_PATH}" != "${UT_DIR}" ]] && msg_blue "UT full path: ${UT_DIR_PATH}"

msg_blue "blacklist file: ${BLACKLIST_FNAME}"
BLACKLIST_PATH="${UT_DIR_PATH}/${BLACKLIST_FNAME}"
[[ ! -f ${BLACKLIST_PATH} ]] && err_exit "${BLACKLIST_PATH} not found"

black_list=(`list_from_file ${BLACKLIST_PATH}`)
#echo "${black_list}"

XML_PATH="${UT_DIR_PATH}/results"
msg_blue "Create result XML dir: ${XML_PATH}"
mkdir -p ${XML_PATH}

exec_list=`find ${UT_DIR_PATH} -executable -type f`

for ut in ${exec_list}; do
    ut_base=`basename ${ut}`
    if in_blacklist "${ut_base}"; then
        msg_yellow "\n${ut_base}: blacklisted"
    else
        msg_blue "\n${ut_base}: execute"
        if [[ "${DRY_RUN}" != true ]]; then
            ut_xml_path="${UT_DIR_PATH}/${ut_base}.xml"
            ut_err_path="${UT_DIR_PATH}/results/${ut_base}.err"

            if [[ "${VERBOSE}" == true ]]; then
                err_msgs=`${ut} 2>&1`
            else
                err_msgs=`${ut} 2>&1 > /dev/null`
            fi

            if [[ -n "${err_msgs}" ]]; then
                echo "${err_msgs}" > ${ut_err_path}
                msg_red "${ut_base}: error messages"
                echo "saved to: ${ut_err_path}"
                if [[ "${VERBOSE}" == true ]]; then
                    echo "${err_msgs}"
                fi
            fi

            if [[ -f ${ut_xml_path} ]]; then
                fstr=`grep 'FailuresTotal' ${ut_xml_path}`
                f=${fstr##*<FailuresTotal>}
                f=${f%%</FailuresTotal>*}
                if [ "${f}" == "0" ]; then
                    msg_green "${ut_base}: OK"
                else
                    msg_red "${ut_base}: ${fstr}"
                fi
                mv ${ut_xml_path} ${XML_PATH}
            fi
        else # dry run
            echo "${ut}"
        fi
    fi
done

