FROM ubuntu:bionic
LABEL maintainer "sungo@joyent.com"
LABEL org.label-schema.vendor "Joyent, Inc"
LABEL org.label-schema.docker.cmd.test "docker run 'make build test'"
LABEL org.label-schema.vcs-url "https://github.com/joyent/conch.git"

# Postgres is included so the user can run `make test` which requires the ability to stand up a real temporary Postgres database
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	ca-certificates \
	carton \
	git \
	libpq-dev \
	libssl-dev \
	libzip-dev \
	postgresql \
	unzip \
&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/conch
WORKDIR /app/conch

COPY . /app/conch

ARG VCS_REF="master"
ARG VERSION="v0.0.0-dirty"

LABEL org.label-schema.vcs-ref $VCS_REF
LABEL org.label-schema.version $VERSION 

RUN make forcebuild

ENV EV_EXTRA_DEFS -DEV_NO_ATFORK
ENV MOJO_CONFIG /app/conch/etc/conch.conf

ENV MOJO_LISTEN http://0.0.0.0:5000
EXPOSE 5000

CMD [ "carton", "exec", "hypnotoad", "-f", "bin/conch" ]
