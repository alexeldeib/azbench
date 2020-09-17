FROM debian:buster as sysstat

RUN apt update && apt install -y git make automake clang

WORKDIR /sysstat
RUN git clone https://github.com/sysstat/sysstat /sysstat
RUN CFLAGS=-static ./configure && CFLAGS=-static make -j$(nproc)

RUN wc -c /sysstat/iostat | numfmt --to=iec-i

FROM ubuntu:18.04

RUN mkdir ~/.gnupg
RUN echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y gnupg2 git tree curl gettext-base

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Add PostgreSQL's repository. It contains the most recent stable release
#  of PostgreSQL.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 12
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y software-properties-common postgresql-12 postgresql-client-12 postgresql-contrib-12

# Install magic-wormhole
RUN apt update && apt install -y python3 python3-pip python3-virtualenv 

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m virtualenv --python=/usr/bin/python3 ${VIRTUAL_ENV}
ENV PATH "$PATH:${VIRTUAL_ENV}/bin"
RUN pip install --upgrade pip setuptools
RUN pip install magic-wormhole

RUN apt install -y locales 
RUN locale-gen en_US.UTF-8

RUN apt install -y git bc
RUN git clone https://github.com/brendangregg/FlameGraph /flamegraph && chmod +x /flamegraph/*.pl
RUN git clone https://github.com/brendangregg/HeatMap /heatmap && chmod +x /heatmap/*.pl

ENV PATH "$PATH:/heatmap:/flamegraph"

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN wormhole

# Install pgio
RUN git clone https://github.com/alexeldeib/pgio

WORKDIR pgio

RUN git checkout ace/debug

COPY entrypoint.sh entrypoint.sh 
COPY --from=sysstat /sysstat/iostat /usr/local/bin/iostat

ENTRYPOINT ["/pgio/entrypoint.sh"]
