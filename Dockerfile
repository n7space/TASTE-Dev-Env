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

ENV WORKSPACE_DIR=/workspace

# Set workspace
WORKDIR ${WORKSPACE_DIR}

# Setup apt dependencies
RUN apt-get update -q && apt-get install -q -y --no-install-recommends \
    apt-transport-https \
    bzip2 \
    build-essential \
    gcc \
    git \
    libglu1-mesa-dev \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    make \
    openjdk-11-jre \
    python3-pexpect \
    python3-pip \
    python3-pygraphviz \
    python3-singledispatch \
    python3-stringtemplate3 \
    spin \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Setup python dependencies
RUN pip3 install \
    black==21.10b0 \
    multipledispatch \
    pyside2 \
    pyside6 \
    pytest

#  Hack antlr3 as required by opengeode
RUN wget -q -O - https://download.tuxfamily.org/taste/antlr3_python3_runtime_3.4.tar.bz2 | tar jxpvf - \
    && cd antlr3_python3_runtime_3.4 \
    && python3 -m pip install --upgrade . \
    && cd .. \
    && rm -rf antlr3_python3_runtime_3.4

# Install MS sources
RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb \
    -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb
# Install .NET 5.0
# This cannot be merged with the previous apt-get due to the need for wget
RUN apt-get update -q && apt-get install -q -y --no-install-recommends \
    dotnet-sdk-6.0 \
    && rm -rf /var/lib/apt/lists/*

# Compile asn1scc
RUN git clone https://github.com/ttsiodras/asn1scc.git \
    && cd asn1scc && dotnet build "asn1scc.sln"

# Install opengeode
RUN git clone https://gitrepos.estec.esa.int/taste/opengeode.git \
    && cd opengeode \
    && make install

# Setup paths for the image end-user
ENV PATH="/root/.local/bin:${WORKSPACE_DIR}/asn1scc/asn1scc/bin/Debug/net6.0/:${PATH}"

# Execute tests to see if the image is valid
RUN opengeode --help
RUN python3 -c "import opengeode"
RUN asn1scc --version
