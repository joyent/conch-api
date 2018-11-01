FROM ubuntu:bionic
LABEL maintainer "sungo@joyent.com"
LABEL org.label-schema.vendor "Joyent, Inc"
LABEL org.label-schema.docker.cmd.test "docker run 'make build test'"
LABEL org.label-schema.vcs-url "https://github.com/joyent/conch.git"

# Postgres is included so the user can run `make test` which requires the ability to stand up a real temporary Postgres database

# The Joyent production database is (as of writing) PostgreSQL 9.6 so we do the
# magic dance to get 9.6 for ourselves, since bionic ships 10.

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends wget gnupg1 ca-certificates

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE 1 
RUN wget -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get update \
&& apt-get upgrade -y --no-install-recommends \
&& apt-get install -y --no-install-recommends \
	software-properties-common \
	build-essential \
	carton \
	git \
	libssl-dev \
	libzip-dev \
	unzip \
&& add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" \
&& apt-get update \
&& apt-get install -y --no-install-recommends \
	postgresql-9.6 \
	postgresql-contrib-9.6 \
	libpq-dev \
&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/conch
WORKDIR /app/conch

COPY . /app/conch

ARG VCS_REF="master"
ARG VERSION="v0.0.0-dirty"

LABEL org.label-schema.vcs-ref $VCS_REF
LABEL org.label-schema.version $VERSION 

RUN make forcebuild

ENV LANG C.UTF-8
ENV EV_EXTRA_DEFS -DEV_NO_ATFORK
ENV MOJO_CONFIG /app/conch/etc/conch.conf

ENV MOJO_LISTEN http://0.0.0.0:5000
EXPOSE 5000

CMD [ "carton", "exec", "hypnotoad", "-f", "bin/conch" ]
