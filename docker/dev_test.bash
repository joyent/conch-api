#!/usr/bin/env bash
: ${PREFIX:=$USER}

docker volume create ${PREFIX}-api-test-carton
PREFIX=${PREFIX} docker/builder.sh --file Dockerfile.dev .

docker/remove_old_images.bash

docker run \
	--mount type=volume,src=${PREFIX}-api-test-carton,dst=/app/conch/local \
	--rm \
	${PREFIX}/conch-api

