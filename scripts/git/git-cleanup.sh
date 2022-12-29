#!/usr/bin/env bash
for dir in */; do
    for fldr in .tox .testr .stestr .git/refs/changes; do
        if [ -d "${dir}${fldr}" ]; then
            echo "found junk ${fldr} in $dir, removing..."
            rm -rf "${dir}${fldr}"
        fi
    done
    if [ -d "${dir}.git" ]; then
        echo "Running git GC in ${dir}"
        git -C ${dir} gc --aggressive
    fi
done
