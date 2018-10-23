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

SHELL := /bin/bash

SILO_IMG := grpn/ansible-silo
SILO_VERSION := $(shell cat VERSION)

BASE_IMG := grpn/ansible-silo-base
BASE_VERSION := 2.0.1

ansible-silo: validate-version
	@docker build --build-arg "v=$(SILO_VERSION)" --tag "${SILO_IMG}:$(SILO_VERSION)" .
	@echo ""
	@echo "To install '${SILO_IMG}:${SILO_VERSION}' for just your user, run the following command:"
	@echo "  docker run --interactive --tty --rm --volume \"\$${HOME}/bin:/silo_install_path\" ${SILO_IMG}:${SILO_VERSION} --install"
	@echo ""
	@echo "To install '${SILO_IMG}:${SILO_VERSION}' for all users, run the following command:"
	@echo "  docker run --interactive --tty --rm --volume \"/usr/local/bin:/silo_install_path\" ${SILO_IMG}:${SILO_VERSION} --install"

ansible-silo-base:
	@docker build --build-arg "v=$(BASE_VERSION)" --file "base.Dockerfile" --tag "${BASE_IMG}:$(BASE_VERSION)" .

push-base:
	@docker push "$(BASE_IMG):$(BASE_VERSION)"

tag: validate-version
	@git tag -a "v$(SILO_VERSION)" -m 'Creates tag "v$(SILO_VERSION)"'
	@git push --tags

untag: validate-version
	@git push --delete origin "v$(SILO_VERSION)"
	@git tag --delete "v$(SILO_VERSION)"

release: tag

re-release: untag tag

validate-version:
	@if [[ ! "$(SILO_VERSION)" =~ ^[0-9]+(\.[0-9]+)+(-[0-9]){0,2}$$ ]]; then\
	  echo "Version must be in format X.Y.Z, e.g. 1.2.3. Given: $(SILO_VERSION)" >&2;\
	  exit 1;\
	fi

test-style:
	@tests/style

test-links:
	@tests/links

test-function:
	@tests/functional

test: validate-version test-style test-links test-function
