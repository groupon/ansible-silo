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

FROM python:2.7.14-alpine3.6

ENV container docker
ARG v
ENV SILO_BASE_VERSION ${v:-UNDEFINED}

ADD pip/pip.conf /etc/pip.conf

LABEL maintainer="Daniel Schroeder <daniel.schroeder@groupon.com>"

# Add testing repo, as we need this for installing gosu
RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Install common libraries
RUN apk add --no-cache libssl1.0==1.0.2n-r0\
                       libatomic==6.3.0-r4\
                       libgomp==6.3.0-r4\
                       libffi==3.2.1-r3\
                       libgcc==6.3.0-r4\
                       libstdc++==6.3.0-r4\
                       libxml2==2.9.5-r0\
                       libgpg-error==1.27-r0\
                       libgcrypt==1.7.9-r0\
                       libxslt==1.1.29-r3\

# Install development libaries
                       libxml2-dev==2.9.5-r0\
                       libxslt-dev==1.1.29-r3\
                       libffi-dev==3.2.1-r3\
                       pkgconf==1.3.7-r0\
                       musl-dev==1.1.16-r14\
                       python2==2.7.14-r0\
                       python2-dev==2.7.14-r0\
                       openssl-dev==1.0.2n-r0\
                       zlib-dev==1.2.11-r0\

# Install curl
                       openssl==1.0.2n-r0\
                       curl==7.58.0-r0\

# Install bash
                       bash==4.3.48-r1\

# Install git
                       pcre==8.41-r0\
                       git==2.13.5-r0\

# Install python
                       py-netifaces==0.10.5-r3\
                       py2-netifaces==0.10.5-r3\

# Install Ansible dependencies
                       yaml==0.1.7-r0\
                       gmp==6.1.2-r0\

# Install gosu, which enables us to run Ansible as the user who started the container
                       gosu@testing=1.9-r0\
                       sudo==1.8.19_p2-r0\

# Install ssh
                       openssh-keygen==7.5_p1-r2\
                       openssh-client==7.5_p1-r2\
                       openssh-sftp-server==7.5_p1-r2\
                       openssh==7.5_p1-r2\
                       sshpass==1.06-r0\

# Install tools for compiling python
                       gcc==6.3.0-r4\
                       binutils-libs==2.28-r3\
                       binutils==2.28-r3\
                       isl==0.17.1-r0\
                       mpfr3==3.1.5-r0\
                       make==4.2.1-r0\
                       mpc1==1.0.3-r0 &&\

# Add the python libraries
    pip install asn1crypto==0.24.0\
                bcrypt==3.1.4\
                cffi==1.11.4\
                cryptography==2.1.4\
                enum34==1.1.6\
                idna==2.6\
                ipaddress==1.0.19\
                lxml==4.1.1\
                paramiko==2.4.0\
                pyasn1==0.4.2\
                pycparser==2.18\
                pynacl==1.2.1\
                napalm==2.3.0\
                six==1.11.0 &&\

    apk del --no-cache gcc\
                       python2-dev\
                       musl-dev\
                       binutils-libs\
                       binutils\
                       isl\
                       libgomp\
                       libatomic\
                       libgcc\
                       mpfr3\
                       mpc1\
                       libstdc++\
                       zlib-dev\
                       python2-dev\
                       openssl-dev\
                       libffi-dev\
                       libxml2-dev\
                       libxslt-dev

# Install docker command and ensure it's always executed w/ sudo
RUN curl -fL -o /tmp/docker.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-17.06.0-ce.tgz" &&\
    tar -xf /tmp/docker.tgz --exclude docker/docker?* -C /tmp &&\
    mv /tmp/docker/docker /usr/local/bin/real-docker &&\
    rm -rf /tmp/docker /tmp/docker.tgz &&\
    echo "#!/usr/bin/env bash" > /usr/local/bin/docker &&\
    echo 'sudo /usr/local/bin/real-docker "$@"' >> /usr/local/bin/docker &&\
    chmod +x /usr/local/bin/docker
