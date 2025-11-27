#!/usr/bin/env bash
# downloads whole site ignoring index.htm[l] files
URL=${1%/} # strip trailing slash so that counting CUT_DIRS is deterministic
URL=${URL//\/ui\/native\//\/artifactory\/} # mangle Artifactory browser URL into artifactory download URL
if [ -z "${URL}" ]; then
    echo "need URL to mirror files from"
    exit 1
fi
slashes="${URL//[^\/]}"  # leave only slashes from URL
num_slashes="${#slashes}" # count them
CUT_DIRS=$(( num_slashes - 3 )) # account for schema and hostname slashes

# TODO: accept regexes for --reject as input
wget --mirror \
     --no-host-directories \
     --no-parent \
     --cut-dirs ${CUT_DIRS} \
     --reject='index.htm*' \
     "${URL}/"
