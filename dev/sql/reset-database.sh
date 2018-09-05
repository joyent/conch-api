#!/bin/sh

BASEDIR=$(cd `dirname $0` && pwd)

sudo -u postgres psql -d postgres -c 'DROP DATABASE conch'
sudo -u postgres psql -d postgres -c 'DROP USER conch'
sudo -u postgres psql -d postgres -c 'CREATE ROLE conch LOGIN'
sudo -u postgres psql -d postgres -c 'CREATE DATABASE conch OWNER conch'
sudo -u postgres psql -U postgres -d conch -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
sudo -u postgres psql -U postgres -d conch -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto";'

$BASEDIR/../../sql/run_migrations.sh
