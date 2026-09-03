#!/usr/bin/env bash
# downloads whole site ignoring index.htm[l] files
URL=${1%/} # strip trailing slash so that counting CUT_DIRS is deterministic
URL=${URL//\/ui\/native\//\/artifactory\/} # convert Artifactory UI browser URL into artifactory download URL
if [ -z "${URL}" ]; then
    echo "need URL to mirror files from"
    exit 1
fi
slashes="${URL//[^\/]}"  # leave only slashes from URL
num_slashes="${#slashes}" # count them
CUT_DIRS=$(( num_slashes - 3 )) # account for schema and hostname slashes

#TODO: autodetect default as half available cores
NUM_THREADS=${2:-4}

downloader="wget"
download_opts=" --mirror "
download_opts+=" --no-host-directories "
download_opts+=" --no-parent "
download_opts+=" --cut-dirs ${CUT_DIRS} "
# TODO: accept regexes for --reject as input
download_opts+=" --reject 'index.htm*' "
if command wget2 > /dev/null 2>&1; then
    downloader="wget2"
    download_opts+=" --max-threads ${NUM_THREADS}"
fi

# shellcheck disable=SC2086 # word split of $download_opts is intentional
${downloader} ${download_opts} "${URL}/"
