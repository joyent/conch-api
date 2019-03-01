#!/usr/bin/env bash

: ${PREFIX:=$USER}
: ${LABEL:="latest"}
: ${BUILDNUMBER:=0}

LABEL=$(echo "${LABEL}" | sed 's/\//_/g')

docker volume create ${PREFIX}-conch-api-carton

set -euo pipefail
IFS=$'\n\t'

PREFIX=${PREFIX} LABEL=${LABEL} docker/builder.sh --file Dockerfile.dev .

docker run \
	--mount type=volume,src=${PREFIX}-conch-api-carton,dst=/app/conch/local \
	--rm \
	--name ${PREFIX}_${BUILDNUMBER} \
	${PREFIX}/conch-api:${LABEL}
