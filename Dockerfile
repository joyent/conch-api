FROM ubuntu:bionic
LABEL maintainer "sungo@joyent.com"
LABEL org.label-schema.vendor "Joyent, Inc"
LABEL org.label-schema.docker.cmd.test "docker run 'make build test'"
LABEL org.label-schema.vcs-url "https://github.com/joyent/conch.git"

# Postgres is included so the user can run `make test` which requires the ability to stand up a real temporary Postgres database

# The Joyent production database is (as of writing) PostgreSQL 9.6 so we do the
# magic dance to get 9.6 for ourselves, since bionic ships 10.

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		carton \
		git \
		libssl-dev \
		libzip-dev \
		perl-doc \
		unzip \
	&& apt-get clean

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		curl \
		gnupg2 \
		software-properties-common \
	&& apt-get clean

RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		postgresql-9.6 \
		postgresql-contrib-9.6 \
		libpq-dev \
	&& apt-get clean

RUN mkdir -p /app/conch
WORKDIR /app/conch

COPY . /app/conch

ARG VCS_REF="master"
ARG VERSION="v0.0.0-dirty"

LABEL org.label-schema.vcs-ref $VCS_REF
LABEL org.label-schema.version $VERSION

ENV HARNESS_OPTIONS j6:c
RUN make forcebuild && rm -r local/cache && rm -r ~/.cpanm

ENV LANG C.UTF-8
ENV EV_EXTRA_DEFS -DEV_NO_ATFORK
ENV MOJO_CONFIG /app/conch/etc/conch.conf

# The port hypnotoad listens on is defined in its config so the exposed port
# may need to be changed at runtime to match that config.
EXPOSE 5000

ENTRYPOINT ["carton", "exec"]
CMD ["hypnotoad", "-f", "bin/conch"]
