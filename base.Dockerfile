# Copyright (c) 2017, Groupon, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# Neither the name of GROUPON nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

FROM alpine:3.6

ENV container docker
ARG v
ENV SILO_BASE_VERSION ${v:-UNDEFINED}

ADD pip/pip.conf /etc/pip.conf

LABEL maintainer="Daniel Schroeder <daniel.schroeder@groupon.com>"

# Add testing repo, as we need this for installing gosu
RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories &&\

# Install curl
    apk add --no-cache openssl=1.0.2k-r0\
                       ca-certificates=20161130-r2\
                       libssh2=1.8.0-r1\
                       libcurl=7.55.0-r0\
                       curl=7.55.0-r0\

# Install bash
                       ncurses-terminfo-base=6.0-r8\
                       ncurses-terminfo=6.0-r8\
                       ncurses-libs=6.0-r8\
                       readline=6.3.008-r5\
                       bash=4.3.48-r1\

# Install git
                       perl=5.24.1-r2\
                       expat=2.2.0-r1\
                       pcre=8.41-r0\
                       git=2.13.5-r0\

# Install python
                       libbz2=1.0.6-r5\
                       libffi=3.2.1-r3\
                       gdbm=1.12-r0\
                       sqlite-libs=3.18.0-r0\
                       py-netifaces=0.10.5-r3\

# Install pip
                       py2-pip=9.0.1-r1\

# Install Ansible dependencies
                       yaml=0.1.7-r0\
                       gmp=6.1.2-r0\

# Install gosu, which enables us to run Ansible as the user who started the container
                       gosu@testing=1.9-r0\
                       sudo=1.8.19_p2-r0\

# Install ssh
                       openssh-client=7.5_p1-r1\
                       openssh-sftp-server=7.5_p1-r1\
                       openssh=7.5_p1-r1\
                       sshpass=1.06-r0 &&\

# Install some required python modules which need compiling
    apk add --no-cache gcc=6.3.0-r4\
                       musl=1.1.16-r13\
                       musl-dev=1.1.16-r13\
                       musl-utils=1.1.16-r13\
                       binutils-libs=2.28-r2\
                       binutils=2.28-r2\
                       isl=0.17.1-r0\
                       libgomp=6.3.0-r4\
                       libatomic=6.3.0-r4\
                       pkgconf=1.3.7-r0\
                       libgcc=6.3.0-r4\
                       mpfr3=3.1.5-r0\
                       mpc1=1.0.3-r0\
                       libstdc++=6.3.0-r4\
                       zlib-dev=1.2.11-r0\
                       python2-dev=2.7.13-r1\
                       openssl-dev=1.0.2k-r0\
                       libffi-dev=3.2.1-r3\
                       libxml2-dev=2.9.4-r4\
                       libxslt-dev=1.1.29-r3 &&\

    pip install asn1crypto==0.22.0\
                cffi==1.10.0\
                cryptography==2.0.2\
                enum34==1.1.6\
                idna==2.5\
                ipaddress==1.0.18\
                ncclient==0.5.3\
                paramiko==1.16.0\
                pycparser==2.18\
                pycrypto==2.6.1\
                six==1.10.0 &&\

    apk del --no-cache gcc\
                       python2-dev\
                       musl-dev\
                       binutils-libs\
                       binutils\
                       isl\
                       libgomp\
                       libatomic\
                       pkgconf\
                       libgcc\
                       mpfr3\
                       mpc1\
                       libstdc++\
                       zlib-dev\
                       python2-dev\
                       openssl-dev\
                       libffi-dev\
                       libxml2-dev\
                       libxslt-dev &&\

 # Install docker command and ensure it's always executed w/ sudo
    curl -fL -o /tmp/docker.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-17.06.0-ce.tgz" &&\
    tar -xf /tmp/docker.tgz --exclude docker/docker?* -C /tmp &&\
    mv /tmp/docker/docker /usr/local/bin/real-docker &&\
    rm -rf /tmp/docker /tmp/docker.tgz &&\
    echo "#!/usr/bin/env bash" > /usr/local/bin/docker &&\
    echo 'sudo /usr/local/bin/real-docker "$@"' >> /usr/local/bin/docker &&\
    chmod +x /usr/local/bin/docker
