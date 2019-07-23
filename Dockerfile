FROM ubuntu:bionic

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get upgrade -y --no-install-recommends && \
	apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		carton \
		curl \
		git \
		libssl-dev \
		libzip-dev \
		perl-doc \
		unzip \
		postgresql \
		libpq-dev \
	&& apt-get clean

RUN mkdir -p /app/conch
WORKDIR /app/conch

COPY . /app/conch

ARG VCS_REF="master"
ARG VERSION="v0.0.0-dirty"

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
