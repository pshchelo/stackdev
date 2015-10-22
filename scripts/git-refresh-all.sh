#!/bin/bash

TOP_DIR=$1
for dir in ${TOP_DIR}/*/; do
    if [ -d $dir/.git ]; then
        cd $dir
        echo "*** Updating $dir ***"
        branch=$(git symbolic-ref --short HEAD)
        git stash
        git remote update
        git checkout master
        git pull
        git checkout $branch
        echo ""
    fi
done
