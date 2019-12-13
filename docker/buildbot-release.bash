#!/usr/bin/env bash

: ${PREFIX:="joyentbuildops"}
: ${LABEL:="latest"}
: ${BUILDNUMBER:=0}

LABEL=$(echo "${LABEL}" | sed 's/\//_/g')
PREFIX=${PREFIX} LABEL=${LABEL} docker/builder.sh --no-cache --file Dockerfile .

docker run \
    --name ${PREFIX}_${BUILDNUMBER} \
    --rm \
    --entrypoint=make \
    ${PREFIX}/conch-api:${LABEL} \
    test
