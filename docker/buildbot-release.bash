#!/usr/bin/env bash

: ${PREFIX:="joyentbuildops"}
: ${LABEL:="latest"}
: ${BUILDNUMBER:=0}

LABEL=$(echo "${LABEL}" | sed 's/\//_/g')
PREFIX=${PREFIX} LABEL=${LABEL} docker/builder.sh --file Dockerfile .

docker run \
	--name ${PREFIX}_${BUILDNUMBER} \
	--rm \
	${PREFIX}/conch-api:${LABEL} \
	--entrypoint=make \
	test \
&& \
docker push ${PREFIX}/conch-api:${LABEL}

docker rmi ${PREFIX}/conch-api:${LABEL}
