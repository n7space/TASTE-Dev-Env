#-------------------------------#
# Development/build environment #
#-------------------------------#

FROM  debian:11.2 as taste-dev-env

# Meta
LABEL VENDOR="N7 Space"
LABEL ARTEFACT="TASTE Development Environment"
LABEL DESCRIPTION="Build environment for additional TASTE tools"

ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true
ENV PATH="/asn1scc/asn1scc/bin/Debug/net5.0/:${PATH}"

# Setup apt dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    git \
    libglu1-mesa-dev \
    make \
    openjdk-11-jre \
    python3-pexpect \
    python3-pip \
    python3-pygraphviz \
    python3-singledispatch \
    python3-stringtemplate3 \
    spin \
    wget

# Setup python dependencies
RUN pip3 install \
    black==21.10b0 \
    multipledispatch \
    opengeode \
    pyside2 \
    pytest

#  Hack antlr3 as required by opengeode
RUN mkdir -p tmp ;	cd /tmp ; wget -q -O - https://download.tuxfamily.org/taste/antlr3_python3_runtime_3.4.tar.bz2 | tar jxpvf - ; cd antlr3_python3_runtime_3.4 ; python3 -m pip install --upgrade .

# Install MS sources
RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb \
    -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb
# Install .NET 5.0
# This cannot be merged with the previous apt-get due to the need for wget
RUN apt-get update && apt-get install -y \
    dotnet-sdk-5.0

# Compile asn1scc
RUN git clone https://github.com/ttsiodras/asn1scc.git \
    && cd asn1scc && dotnet build "asn1scc.sln"

# Execute tests to see if the image is valid
RUN opengeode --help
RUN asn1scc --version