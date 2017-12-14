#!/bin/bash -e

test $MANTA_USER || (echo '$MANTA_USER must be defined' && exit 1);
test $1 || (echo 'First argument must be local directory for manta job' && exit 1);
test $2 || (echo 'Second argument must be Manta path for job inputs' && exit 1);

manta_job_dir=$1
job_name=$(basename $manta_job_dir)

test -f $manta_job_dir/job.json || (echo "$manta_job_dir must have job.json file" && exit 1)

manta_input_dir=$2

echo 'Uploading job files...'
muntar -f <(tar -cf - $manta_job_dir) ~~/stor/job
echo 'Done.'

echo 'Starting Manta job'
mfind $manta_input_dir | mjob create -f <(perl -pe 's/\$([_A-Z]+)/$ENV{$1}/g' $manta_job_dir/job.json) -n "$job_name"
