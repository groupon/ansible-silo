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

FROM grpn/ansible-silo-base:2.0.1

ENV ANSIBLE_VERSION v2.4.2.0-1
ENV ANSIBLE_LINT_VERSION v3.4.13
ENV SILO_IMAGE grpn/ansible-silo

ADD silo /silo/

# Install pip modules from requirements file
ADD pip/requirements /tmp/pip-requirements.txt
RUN pip install -r /tmp/pip-requirements.txt

# Installing Ansible from source
RUN git clone --progress https://github.com/ansible/ansible.git /silo/userspace/ansible 2>&1 &&\
    cd /silo/userspace/ansible &&\
    git checkout --force ${ANSIBLE_VERSION} 2>&1 &&\
    git submodule update --init --recursive 2>&1 &&\
    git clone --progress https://github.com/willthames/ansible-lint /silo/userspace/ansible-lint 2>&1  &&\
    cd /silo/userspace/ansible-lint &&\
    git checkout --force ${ANSIBLE_LINT_VERSION} 2>&1 &&\

# Create directory for storing ssh ControlPath
    mkdir -p /home/user/.ssh/tmp &&\

# Give the user a custom shell prompt
    echo 'export PS1="[ansible-silo $SILO_VERSION|\w]\\$ "' > /home/user/.bashrc &&\

# Set default control path in ssh config
    echo "ControlPath  /home/user/.ssh/tmp/%h_%p_%r" > /etc/ssh/ssh_config &&\

# User pip installs should be written to custom location
    echo "install-option = --install-scripts=/silo/userspace/bin --prefix=/silo/userspace" >> /etc/pip.conf &&\

# Grant write access to the userspace sub directories
    chmod 777 /silo/userspace/bin /silo/userspace/lib

ENTRYPOINT ["/silo/entrypoint"]

CMD []

ARG v
ENV SILO_VERSION ${v:-UNDEFINED}
