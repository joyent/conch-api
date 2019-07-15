#!/usr/bin/env bash

: ${PREFIX:="joyent"}
: ${LABEL:="latest"}

TAG=`git describe`
HASH=`git rev-parse HEAD`

LABEL=$(echo "${LABEL}" | sed 's/\//_/g')

docker build \
	--force-rm \
	-t ${PREFIX}/conch-api:${LABEL} \
	--build-arg VERSION=${TAG} \
	--build-arg VCS_REF=${HASH} \
	$@
