#!/usr/bin/env bash

docker images -a -f dangling=true | \
	grep "<none>" | \
	awk "{print \$3}" | \
	xargs -n 1 docker rmi

