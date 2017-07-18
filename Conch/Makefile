test:
	@carton exec prove -l lib

run:
	@carton exec plackup bin/app.psgi

deps: install-deps
install-deps:
	@carton install

generate-dbic:
	@carton exec dbicdump schema.conf
