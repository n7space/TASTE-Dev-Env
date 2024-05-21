#-------------------------------#
# Development/build environment #
#-------------------------------#

FROM  debian:11.9 as taste-dev-env

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
    autoconf \
    autotools-dev \
    automake \
    bzip2 \
    build-essential \
    gcc \
    git \
    libfl-dev \
    libglu1-mesa-dev \
    libncurses5 \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    libtool \
    make \
    openjdk-11-jre \
    pkg-config \
    python3-pexpect \
    python3-pip \
    python3-pygraphviz \
    python3-singledispatch \
    python3-stringtemplate3 \
    spin \
    wget \
    socat \
    bison \
    && rm -rf /var/lib/apt/lists/*

# Setup python dependencies
RUN pip3 install \
    black==21.10b0 \
    click==8.0.2 \
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
    dotnet-sdk-7.0 \
    && rm -rf /var/lib/apt/lists/*

# Compile asn1scc
RUN git clone https://github.com/maxime-esa/asn1scc.git \
    && cd asn1scc \
    && git checkout 4.5.1.5 \
    && dotnet build "asn1scc.sln"

# Install opengeode
RUN git clone https://gitrepos.estec.esa.int/taste/opengeode.git \
    && cd opengeode \
    && PATH=~/.local/bin:"${PATH}" && pyside6-rcc opengeode.qrc -o opengeode/icons.py &&  python3 -m pip install --upgrade .

# Install CppUTest
RUN git clone --branch v4.0 --depth 1 https://github.com/cpputest/cpputest.git \
    && cd cpputest/ \
    && mkdir -p /opt/cpputest \
    && mkdir -p build_cpputest \
    && cd build_cpputest \
    && autoreconf .. -i \
    && ../configure \
       --prefix=/opt/cpputest \
       --enable-std-cpp17 \
       --disable-memory-leak-detection \
    && make \
    && make install \
    && cd ../.. \
    && rm -rf cpputest

# Download RTEMS
RUN wget -q https://rtems-qual.io.esa.int/public_release/rtems-6-sparc-gr712rc-smp-4.tar.xz \
    && tar -xf rtems-6-sparc-gr712rc-smp-4.tar.xz -C /opt \
    && rm -f rtems-6-sparc-gr712rc-smp-4.tar.xz

# Download and build n7s-spin
RUN git clone https://github.com/n7space/Spin.git \
    && cd Spin \
    && make \
    && mkdir -p /opt/n7s-spin/ \
    && cp Src/spin /opt/n7s-spin/n7s-spin

# Setup paths for the image end-user
ENV PATH="/opt/cpputest:/opt/n7s-spin:/opt/rtems-6-sparc-gr712rc-smp-4/bin:/root/.local/bin:${WORKSPACE_DIR}/asn1scc/asn1scc/bin/Debug/net6.0/:${PATH}"

# Execute tests to see if the image is valid
RUN opengeode --help
RUN python3 -c "import opengeode"
RUN asn1scc --version
RUN black --version
RUN n7s-spin -V
RUN cd /opt/rtems-6-sparc-gr712rc-smp-4/src/example && make
RUN find /opt/cpputest/lib/libCppUTest.a
