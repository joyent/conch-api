.PHONY: test run build deps install-deps generate-dbic watch


test:
	@carton exec prove -l lib

run: build
	@carton exec plackup bin/app.psgi

build: public/js/app.js public/css/app.css


deps: install-deps
install-deps:
	# '--deployment' installs the same dep versions that are in the lockfile
	@carton install --deployment

generate-dbic:
	@carton exec dbicdump schema.conf


# Build Javascript UI
JS_SRC := $(shell find ui/src -name '*.js')

ui/node_modules:
	@cd ui && npm install;

public/js/app.js: $(JS_SRC) ui/node_modules
	@cd ui && npm run-script build;
	@cp ui/bin/app.js public/js/app.js;

public/css/app.css: public/js/app.js
	@cp ui/css/app.css public/css/app.css;


watch:
	find lib ui/src | entr -r -d -c make run
