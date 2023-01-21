echo 'set -x'
cat $1 | grep -Ev '^(#|$|echo|sleep|clear|teletype)' | sed 's/^telerun //'
