#!/usr/bin/env bash

mkdir -p docs/modules

for file in $(find lib -type f -iname \*.pm); do
	mdfile=$(echo "$file" | sed 's/^lib\///' | sed 's/\//-/g' | sed 's/\.pm$/.md/' | awk '{print tolower($0)}')
	mdpath="docs/modules/$mdfile"

	echo "pod2github $file > $mdpath"
	carton exec pod2github $file > $mdpath
done
