.PHONY: database all

all: deps database

../Conch/local:
	cd ../Conch/ && make local

deps: ../Conch/local

database:
	sql/reset-database.sh
	sql/make-dev-user.sh
