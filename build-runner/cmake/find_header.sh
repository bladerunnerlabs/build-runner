#!/bin/bash

hdr_name=$1

VERBOSE=true

function trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

function search_target_name_in_file()
{
    local hdr_path=$1
    local hdr_name=$2
    local cmake_file=$3

    sed '/${hdr_name}/q' ${hdr_path}/${cmake_file} | grep -A 1 "define_" | tail -n 1
}

function search_target_name()
{
    local hdr_path=$1
    local hdr_name=$2

    if [[ -f "${hdr_path}/CMakeLists.txt" ]]; then
        search_target_name_in_file ${hdr_path} ${hdr_name} "CMakeLists.txt"
    elif [[ -f "${hdr_path}/CMakeLists.auto" ]]; then
        search_target_name_in_file ${hdr_path} ${hdr_name} "CMakeLists.auto"
    fi
}

function get_target()
{
    local hdr_path=`dirname $1`
    local hdr_name=`basename $1`
    local target_name

    target_name=`search_target_name ${hdr_path} ${hdr_name}`
    if [[ -z "${target_name}" ]]; then
        hdr_path=`dirname ${hdr_path}`
        target_name=`search_target_name ${hdr_path} ${hdr_name}`
    fi
    if [[ -n "${target_name}" ]]; then
        echo "`trim ${target_name}`"
    else
        echo "not found"
    fi
}

find . -type d \( -name build \) -prune -o -name ${hdr_name} -print | \
while read hdr_path; do
    if [[ ${VERBOSE} == true ]]; then
        echo "${hdr_path}"
    fi
    echo "target: `get_target ${hdr_path}`"
    echo
done

