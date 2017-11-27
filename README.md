# Conch

Database build and management service

# Setup

Conch uses [`carton`](https://metacpan.org/pod/Carton) to manage Perl
dependencies and `npm` for Perl depdencies.  Both are required for building and
running the project.

Below is a list of useful Make commands that can be used to build and run the
project. All of these should be run in the `Conch/` directory.

* `make build` -- Install dependencies and build Perl and Javascript Source
* `make run` -- Build the project and run it
* `make watch` -- Continuously build and run the code, using [`entr`](http://entrproject.org).
* `make format` -- Auto-format source code
* `make test` -- Run tests
* `make migrate-db` -- Run database migrations


# API

The Conch API is documented at [preflight.scloud.zone/doc](https://preflight.scloud.zone/doc).
