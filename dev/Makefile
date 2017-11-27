.PHONY: database all

all: deps database

../Conch/ui/node_modules:
	cd ../Conch/ && make ui/node_modules

../Conch/local:
	cd ../Conch/ && make local

deps: ../Conch/ui/node_modules ../Conch/local

database:
	../sql/reset-database.sh
	sql/make-dev-user.sh
