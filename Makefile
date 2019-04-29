.PHONY: test run morbo build clean format deps install-deps generate-dbic watch-perl\
	watch doc migrate-db watch-test

run: build morbo ## Default. Build and run under morbo

morbo: ## Run under morbo, listening on :5001
	@carton exec -- morbo -v bin/conch -l http://\*:5001

build: local ## Install deps (TODO: and build docs)

clean:
	\rm -rf local log public/doc

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

doc: public/doc/index.html ## Build docs

.PHONY: ghdocs
ghdocs:
	docs/poddocs.sh

public/doc/index.html: \
	docs/conch-api/openapi-spec.yaml \
	docs/conch-api/yarn.lock docs/conch-api/index.js
	@cd docs/conch-api && yarn install && yarn run render
	@mkdir -p public/doc
	@cp docs/conch-api/index.html public/doc/index.html

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

.PHONY: validation_docs docs/validation/BaseValidation.md docs/validation/TestValidations.md
validation_docs: docs/validation/BaseValidation.md docs/validation/TestingValidations.md ## Generate markdown files of the validation docs

docs/validation/BaseValidation.md: lib/Conch/Validation.pm
	@carton exec pod2github lib/Conch/Validation.pm \
		| perl -p -e's{https://metacpan.org/pod/((?:Test::)?Conch[^)]+)}{"https://github.com/joyent/conch/blob/master/lib/".join("/",split(/::/,$$1)).".pm"}e' \
		> docs/validation/BaseValidation.md

docs/validation/TestingValidations.md: lib/Test/Conch/Validation.pm
	@carton exec pod2github lib/Test/Conch/Validation.pm \
		| perl -p -e's{https://metacpan.org/pod/((?:Test::)?Conch[^)]+)}{"https://github.com/joyent/conch/blob/master/lib/".join("/",split(/::/,$$1)).".pm"}e' \
		> docs/validation/TestingValidations.md

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

