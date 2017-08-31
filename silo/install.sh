#!/usr/bin/env bash
#
# Installation script, copying all executables to a mounted directory
#
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

if [[ ! -d /silo_install_path ]]; then
  echo "Installation path does not exist. You need to mount a local" \
    "directory to /silo_install_path, e.g. -v" \
    "\"\${HOME}/bin:/silo_install_path\"" >&2
  exit "${EX_CANTCREAT}"
fi

echo "Installing from ${SILO_IMAGE_SHORT} ${BUNDLE_VERSION:-${SILO_VERSION}}:"

for src in /silo/bin/*; do
  file="$(basename "${src}")"
  target="/silo_install_path/${file}"
  if [[ -f "${target}" ]]; then
    echo " - ${file} will be updated"
  else
    echo " - ${file} will be created"
  fi
  if [[ -L "${src}" ]]; then
    cp -a "${src}" "${target}"
  else
    render_template "${src}" "${target}"
    chmod +x "${target}"
  fi

done
echo "Done"
