# Conch Report

This directory contains utilities to dump and process data from the Conch
databases, scripts to assist with creating Manta jobs, and files to run Manta
jobs on the raw data.


# Overview

## `/bin`

* `upload_dir_to_manta.sh` -- script to upload a directory to manta. Given a
  path to a directory as the first argument, it creates a GZIPed tarball and
  uploads it to Manta. It then creates a Manta job to decompress and un-tar the
  file into a directory in ~~/stor`. Requies Manta envirnoment variables to be
  set.

* `start_manta_job.sh` -- script to start a Manta job. Given a path to a local
  directory with a `job.json` file ("job directory") and a Manta path to the
  input files as argument, uploads the job directory to Manta and starts a
  Manta job as defined by the `job.json` file. Requires Manta envirnoment
  variables to be set.


## `manta_job`

This directory contains sub-directories ("job directories") which each define
and support a Manta job. Each job directory should contain a `job.json` file to
define the phases and assets for Manta job. The job directory can contain
scripts and supporting files to be used in the Manta job. The entire directory
will be uploaded to Manta, and assets can be used in a Manta phase with the
`"assets"` property in `job.json`.
