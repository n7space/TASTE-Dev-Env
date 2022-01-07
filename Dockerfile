#-------------------------------#
# Development/build environment #
#-------------------------------#

FROM  debian:11.2 as taste-dev-env

# Meta
LABEL VENDOR="N7 Space"
LABEL ARTEFACT="TASTE Development Environment"
LABEL DESCRIPTION="Build environment for additional TASTE tools"

ENV DEBIAN_FRONTEND=noninteractive

# Setup apt dependencies
RUN apt-get update && apt-get install -y \
    git \
    libglu1-mesa-dev \
    make \
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

