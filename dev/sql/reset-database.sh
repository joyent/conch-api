#!/bin/sh

BASEDIR=$(cd `dirname $0` && pwd)

psql -d postgres -c 'DROP DATABASE conch'
psql -d postgres -c 'DROP DATABASE conch'
psql -d postgres -c 'CREATE ROLE conch LOGIN'
psql -d postgres -c 'CREATE DATABASE conch OWNER conch'
psql -U postgres -d conch -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
psql -U postgres -d conch -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto";'

$BASEDIR/../sql/run_migrations.sh
