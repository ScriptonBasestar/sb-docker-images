# NAME:     discourse/base
# VERSION:  release

ARG RUBY_VERSION=3.3.4
ARG DEBIAN_RELEASE=bookworm
# FROM debian:${DEBIAN_RELEASE}-slim
FROM ruby:${RUBY_VERSION}-${DEBIAN_RELEASE}

ARG DEBIAN_RELEASE
ARG RUBY_VERSION
ENV PG_MAJOR=15 \
    RUBY_ALLOCATOR=/usr/lib/libjemalloc.so \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    LEFTHOOK=0 \
    RUBY_VERSION=${RUBY_VERSION} \
    DEBIAN_RELEASE=${DEBIAN_RELEASE}

#LABEL maintainer="Sam Saffron \"https://twitter.com/samsaffron\""

# Ensures that the gid and uid of the following users are consistent to avoid permission issues on directories in the
# mounted volumes.
RUN groupadd --gid 1000 discourse &&\
    useradd --uid 1000 --gid 1000 -m --shell /bin/bash discourse

RUN echo 2.0.`date +%Y%m%d` > /VERSION
RUN echo "deb http://deb.debian.org/debian ${DEBIAN_RELEASE}-backports main" > "/etc/apt/sources.list.d/${DEBIAN_RELEASE}-backports.list"
RUN echo "debconf debconf/frontend select Teletype" | debconf-set-selections
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install gnupg sudo curl fping
RUN sh -c "fping proxy && echo 'Acquire { Retries \"0\"; HTTP { Proxy \"http://proxy:3128\";}; };' > /etc/apt/apt.conf.d/40proxy && apt-get update || true"
RUN apt-mark hold initscripts
RUN apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y locales locales-all
ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

RUN curl --silent --location https://deb.nodesource.com/setup_20.x | sudo bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN apt-get -y update
# install these without recommends to avoid pulling in e.g.
# X11 libraries, mailutils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends git rsyslog logrotate cron ssh-client less
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install autoconf build-essential ca-certificates rsync \
    libxslt-dev libcurl4-openssl-dev \
    libssl-dev libyaml-dev libtool \
    libpcre3 libpcre3-dev zlib1g zlib1g-dev \
    libxml2-dev gawk parallel \
    libpq-dev \
    libreadline-dev anacron wget \
    psmisc whois brotli libunwind-dev \
    libtcmalloc-minimal4 cmake \
    pngcrush pngquant ripgrep poppler-utils

RUN sed -i -e 's/start -q anacron/anacron -s/' /etc/cron.d/anacron
RUN sed -i.bak 's/$ModLoad imklog/#$ModLoad imklog/' /etc/rsyslog.conf
RUN sed -i.bak 's/module(load="imklog")/#module(load="imklog")/' /etc/rsyslog.conf
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN sh -c "test -f /sbin/initctl || ln -s /bin/true /sbin/initctl"
RUN cd / &&\
    DEBIAN_FRONTEND=noninteractive apt-get -y install runit socat &&\
    mkdir -p /etc/runit/1.d &&\
    apt-get clean &&\
    rm -f /etc/apt/apt.conf.d/40proxy &&\
    locale-gen en_US &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs yarn &&\
    npm install -g terser uglify-js pnpm

ADD install-imagemagick /tmp/install-imagemagick
RUN /tmp/install-imagemagick

ADD install-jemalloc /tmp/install-jemalloc
RUN /tmp/install-jemalloc

#ADD install-rust /tmp/install-rust
# ADD install-ruby /tmp/install-ruby
ADD install-oxipng /tmp/install-oxipng
# RUN /tmp/install-rust && /tmp/install-ruby $RUBY_VERSION && /tmp/install-oxipng && rustup self uninstall -y

RUN echo 'gem: --no-document' >> /usr/local/etc/gemrc &&\
    gem update --system

RUN gem install pups --force &&\
    mkdir -p /pups/bin/ &&\
    ln -s /usr/local/bin/pups /pups/bin/pups

# This tool allows us to disable huge page support for our current process
# since the flag is preserved through forks and execs it can be used on any
# process
ADD thpoff.c /src/thpoff.c
RUN gcc -o /usr/local/sbin/thpoff /src/thpoff.c && rm /src/thpoff.c

# clean up for docker squash
RUN rm -fr /usr/share/man &&\
    rm -fr /usr/share/doc &&\
    rm -fr /usr/share/vim/vim74/doc &&\
    rm -fr /usr/share/vim/vim74/lang &&\
    rm -fr /usr/share/vim/vim74/spell/en* &&\
    rm -fr /usr/share/vim/vim74/tutor &&\
    rm -fr /usr/local/share/doc &&\
    rm -fr /usr/local/share/ri &&\
    rm -fr /usr/local/share/ruby-build &&\
    rm -fr /var/lib/apt/lists/* &&\
    rm -fr /root/.gem &&\
    rm -fr /root/.npm &&\
    rm -fr /tmp/*

# this can probably be done, but I worry that people changing PG locales will have issues
# cd /usr/share/locale && rm -fr `ls -d */ | grep -v en`

# this is required for aarch64 which uses buildx
# see https://github.com/docker/buildx/issues/150
RUN rm -f /etc/service

COPY etc/  /etc
COPY sbin/ /sbin
