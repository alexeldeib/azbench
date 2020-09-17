FROM debian:buster

RUN apt update && apt install -y python3 python3-pip python3-virtualenv 

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m virtualenv --python=/usr/bin/python3 ${VIRTUAL_ENV}
ENV PATH "$PATH:${VIRTUAL_ENV}/bin"
RUN pip install --upgrade pip setuptools
RUN pip install magic-wormhole

RUN apt install -y locales 
RUN locale-gen en_US.UTF-8

RUN apt install -y git
RUN git clone https://github.com/brendangregg/FlameGraph /flamegraph && chmod +x /flamegraph/*.pl
RUN git clone https://github.com/brendangregg/HeatMap /heatmap && chmod +x /heatmap/*.pl

ENV PATH "$PATH:/heatmap:/flamegraph"

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN wormhole

ENTRYPOINT [ "wormhole" ]
