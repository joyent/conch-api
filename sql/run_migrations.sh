#!/bin/sh

BASEDIR=$(cd `dirname "$0"` && pwd)

for migration in $(ls $BASEDIR/migrations | sort); do
    psql -U conch -v ON_ERROR_STOP=1 -f $BASEDIR/migrations/$migration;
done
