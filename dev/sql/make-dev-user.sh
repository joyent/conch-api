#!/bin/sh

PSQL="psql -A -U conch -d conch"
BASEDIR=$(cd `dirname $0` && pwd)

$PSQL < $BASEDIR/01-dev-user.sql
