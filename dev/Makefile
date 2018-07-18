.PHONY: database all

all: deps database

../local:
	cd .. && make local

deps: ../local

database:
	sql/reset-database.sh
	sql/make-dev-user.sh
