#!/bin/bash -e

test $1 || (echo 'Must specify local directory to upload' && exit 1)

dir=$1;
name=$(basename $dir);
test -d $dir || (echo "Directory '$dir' does not exist" && exit 1);

tar -czf - $dir | mput "~~/stor/$name.tar.gz"

echo "~~/stor/$name.tar.gz" | mjob create -o -m gzcat -m 'muntar -f $MANTA_INPUT_FILE ~~/stor/'
