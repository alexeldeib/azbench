FROM ubuntu:16.04

WORKDIR /

# switch to azure mirror
RUN sed -i "s://archive\.ubuntu\.com/://azure.archive.ubuntu.com/:" /etc/apt/sources.list

# Update cache
RUN apt-get update -qq -y && \
    apt-get upgrade -qq

# Install https transport which is required for packages.microsoft.com repo
RUN apt-get install -y apt-transport-https gnupg ca-certificates curl

# Add azurecore repository
RUN echo 'deb [arch=amd64] https://packages.microsoft.com/repos/azurecore/ xenial main' | tee /etc/apt/sources.list.d/azure-public-xenial.list
RUN curl -s https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl -s https://packages.microsoft.com/keys/msopentech.asc | apt-key add -
RUN apt-key list

# Update cache
RUN apt-get update -qq -y && \
    apt-get upgrade -qq

# Install Metrics Extension package and socat (utility that we'll be using to emit statsd traffic)
RUN apt-get install -y metricsext2 socat

ENTRYPOINT [ "MetricsExtension" ]
