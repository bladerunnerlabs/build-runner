#!/bin/bash

find_tgt=$1

function trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

function get_targets_of_cmake_file()
{
    local cmake_path=$1

    awk '/define_/{getline; print}' ${cmake_path}
}

find . -type d \( -name build \) -prune -o -name "CMakeLists.txt" -print | \
while read cmk_path; do
    tgt_names_list=`get_targets_of_cmake_file ${cmk_path}`
    for tgt_name in ${tgt_names_list}; do
        tgt_name=`trim ${tgt_name}`
        if [[ "${tgt_name}" == "${find_tgt}" ]]; then
            echo "${cmk_path}"
        fi
    done
done

