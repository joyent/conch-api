#!/bin/sh

BASEDIR=$(cd `dirname $0` && pwd)

psql -d postgres -c 'DROP DATABASE conch'
psql -d postgres -c 'DROP DATABASE conch'
psql -d postgres -c 'CREATE ROLE conch LOGIN'
psql -d postgres -c 'CREATE DATABASE conch OWNER conch'

$BASEDIR/load.sh

