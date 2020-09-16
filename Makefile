.PHONY: test run morbo build clean format deps install-deps generate-dbic watch-perl\
	watch doc migrate-db watch-test

run: build morbo ## Default. Build and run under morbo

morbo: ## Run under morbo, listening on :5001
	@carton exec -- morbo -v bin/conch -l http://\*:5001

build: local ## Install deps (TODO: and build docs)

clean:
	\rm -rf local log

local: cpanfile.snapshot ## Install perl dependencies
# '--deployment' installs the same dep versions that are in the lockfile
	@carton install --deployment && touch local

.PHONY: forcebuild
forcebuild: ## Always run carton
	carton install --deployment

test: local ## Run tests
	@carton exec prove -lpr t/

test_loud: local ## Run tests but tell the Mojo harness to log verbosely to log/
	MOJO_LOG_LEVEL=debug carton exec prove -lpr t/

.PHONY: ghdocs
ghdocs: build
	@rm -rf docs/{modules,scripts,json-schema}
	@carton exec misc/pod2githubpages \
		$$(find lib -type f -iname \*.pm) \
		$$(find bin -type f -perm -u-x -not -name \*swp) \
		$$(find json-schema -type f -iname \*.yaml)

.PHONY: docimages
docimages: build
	@carton exec misc/update-schema-diagrams

watch-test:
	@find lib t | entr -r -c make test

generate-dbic: dbic

.PHONY: dbic
dbic: ## Regenerate DBIC schemas
	@carton exec dbicdump -Ilib schema-loader.yaml
	@make db-schema

migrate-db: ## Apply database migrations
	@sql/run_migrations.sh
	@make db-schema

.PHONY: db-schema
db-schema: ## create a dump of current db schema
	pg_dump --username conch --schema-only --file sql/schema.sql conch

docker_test:
	@echo "============================"
	@echo "This so very experimental."
	@echo "============================"
	@echo "============================"
	bash docker/dev_test.bash

.PHONY: help
help: ## Display this help message
	@echo "GNU make(1) targets:"
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
