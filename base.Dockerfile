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

FROM alpine:3.4

ENV container docker
ARG v
ENV SILO_BASE_VERSION ${v:-UNDEFINED}

MAINTAINER daniel.schroeder@groupon.com

# Add testing repo, as we need this for installing gosu
RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories &&\
    echo "@community http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories &&\

# Install curl
apk add --no-cache openssl=1.0.2k-r0\
                   ca-certificates=20161130-r0\
                   libssh2=1.7.0-r0\
                   libcurl=7.52.1-r2\
                   curl=7.52.1-r2\

# Install bash
                   ncurses-terminfo-base=6.0-r7\
                   ncurses-terminfo=6.0-r7\
                   ncurses-libs=6.0-r7\
                   readline=6.3.008-r4\
                   bash=4.3.42-r5\

# Install git
                   perl=5.22.2-r0\
                   expat=2.2.0-r0\
                   pcre=8.38-r1\
                   git=2.8.5-r0\

# Install python
                   libbz2=1.0.6-r5\
                   libffi=3.2.1-r2\
                   gdbm=1.11-r1\
                   sqlite-libs=3.13.0-r0\
                   python=2.7.12-r0\
                   py-six=1.10.0-r0\

# Install Ansible dependencies
                   yaml=0.1.6-r1\
                   py-yaml=3.11-r0\
                   py-markupsafe=0.23-r0\
                   py-jinja2=2.8-r0\
                   gmp=6.1.0-r0\
                   py-crypto=2.6.1-r0\
                   py-cryptography=1.3.1-r0\
                   py-ecdsa=0.13-r0\
                   py-httplib2=0.9.2-r2\
                   py-paramiko=1.16.0-r0\
                   py2-ptyprocess@community=0.5.1-r3\
                   py2-pexpect@community=4.2.1-r1\

# Install gosu, which enables us to run Ansible as the user who started the container
                   gosu@testing=1.9-r0\
                   sudo=1.8.16-r0\

# Install ssh
                   openssh-client=7.2_p2-r4\
                   openssh-sftp-server=7.2_p2-r4\
                   openssh=7.2_p2-r4 &&\

# Install py-netaddr, currently not available for Alpine 3.4
cd /tmp &&\
wget https://files.pythonhosted.org/packages/source/n/netaddr/netaddr-0.7.18.tar.gz &&\
tar -xzvf netaddr-0.7.18.tar.gz &&\
cd netaddr-0.7.18 &&\
sudo python2 setup.py install --prefix=/usr &&\
rm -rf /tmp/netaddr-0.7.18.tar.gz /tmp/netaddr-0.7.18
