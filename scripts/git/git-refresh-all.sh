#!/bin/bash

TOP_DIR=$1
for dir in ${TOP_DIR}/*/; do
    if [ -d $dir/.git ]; then
        echo "*** Updating $dir ***"
        $git_cmd="git -C $dir"
        branch=$($git_cmd symbolic-ref --short HEAD)
        $git_cmd stash
        $git_cmd checkout master
        $git_cmd pull --all
        $git_cmd checkout $branch
        echo ""
    fi
done
