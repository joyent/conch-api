#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

BASEDIR=$(cd `dirname "$0"` && pwd)
DATABASE="${1:-conch}"

date "+%Y-%m-%d %T"
for migration in $(ls $BASEDIR/migrations | sort); do
    echo $BASEDIR/migrations/$migration
    psql -U conch $DATABASE -v ON_ERROR_STOP=1 -f $BASEDIR/migrations/$migration;
    date "+%Y-%m-%d %T"
done
