FROM debian:buster as sysstat

RUN apt update && apt install -y git make automake clang

WORKDIR /sysstat
RUN git clone https://github.com/sysstat/sysstat /sysstat
RUN CFLAGS=-static ./configure && CFLAGS=-static make -j$(nproc)

RUN wc -c /sysstat/iostat | numfmt --to=iec-i

FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y gnupg2

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#  of PostgreSQL.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 12
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y software-properties-common postgresql-12 postgresql-client-12 postgresql-contrib-12

COPY entrypoint.sh entrypoint.sh
COPY --from=sysstat /sysstat/iostat /usr/local/bin/iostat

ENTRYPOINT ["/entrypoint.sh"]
