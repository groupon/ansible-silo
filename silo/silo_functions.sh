#!/usr/bin/env bash
#
# Ansible silo lib, containing functions used by ansible-silo and silo bundles
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

# SILO_IMAGE is an env var defined in silo/bin/ansible-silo, originating from
# Dockerfile. It holds the name of the Docker image including the repository
# path.
# SILO_IMAGE_SHORT is based on SILO_IMAGE, the path is removed and will only
# contain the name (basically a basename)
readonly SILO_IMAGE_SHORT="${SILO_IMAGE##*/}"

# shellcheck disable=SC1091
source /silo/exit_codes.sh


#######################################
# Validates volume content and attempts to fix
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
check_compatibility() {
  # If userspace directly contains ansible, this is a volume mounted from Silo
  # 1.x.x. We convert it to the new directory layout, introduced with Silo
  # 2.0.0
  if [[ -d "/silo/userspace/.git" ]] && grep -q "github.com/ansible/ansible" \
    /silo/userspace/.git/config; then
    echo "Found old volume layout. Converted directory structure."
    cp -R /silo/userspace /tmp/ansible
    cd /silo/userspace || exit
    # shellcheck disable=SC2046
    rm -rf $(ls -A /silo/userspace)
    mkdir bin lib
    chmod 777 bin lib
    mv /tmp/ansible /silo/userspace/ansible
  fi

  # Install ansible-lint if not present in userspace. ansible-lint used to be
  # installed in /silo/ansible-lint via git until v2.0.3
  if [[ ! -f "/silo/userspace/bin/ansible-lint" ]]; then
    echo "ansible-lint is missing, probably due to update of ansible-silo."
    echo "Since v2.0.4 ansible-lint will be installed in userspace."
    echo "Installing now..."
    # Deleting old symlink
    rm -rf "/silo/userspace/bin/ansible-lint"
    pip install --no-deps ansible-lint=="${ANSIBLE_LINT_VERSION}"
  fi
}

#######################################
# Sets up Ansible from cloned source and put logfile into place
# Globals:
#   ANSIBLE_LOG_PATH
#   PYTHONPATH
# Arguments:
#   None
# Returns:
#   None
#######################################
prepare_ansible() {
  local log_path user_modules
  chmod +x /silo/userspace/ansible/hacking/env-setup
  # shellcheck disable=SC1091
  source /silo/userspace/ansible/hacking/env-setup silent
  user_modules="/silo/userspace/lib/python2.7/site-packages"
  # PYTHONPATH defines the search path for Python module files
  export PYTHONPATH="${user_modules}:${PYTHONPATH}"

  # If ANSIBLE_LOG_PATH was already set by the user.
  # ANSIBLE_LOG_PATH is used by Ansible to define log file location.
  if [[ -n "${ANSIBLE_LOG_PATH}" ]]; then
    link_log "${ANSIBLE_LOG_PATH}"
    return
  fi

  # If we have a mounted ansible.cfg ...
  if [[ -f "/home/user/playbooks/ansible.cfg" ]]; then
    # and if it contains a log_path option
    if grep -q "^log_path\\s*=" "/home/user/playbooks/ansible.cfg"; then
      # shellcheck disable=SC1090
      source <(grep log_path /home/user/playbooks/ansible.cfg \
        | sed 's/ *= */=/g')
      link_log "${log_path}"
      return
    fi
  fi

  # else, we define the default log path
  link_log "/var/log/ansible.log"
}

#######################################
# Put logfile into place
# We log to /silo/log/ansible.log as Ansible 2.0.0.x throws a warning if parent
# directory is not writable. Ansibles default log file is /var/log/ansible.log
# and /var/log is owned by root, which would always trigger a warning
# Globals:
#   None
# Arguments:
#   logfile path
# Returns:
#   None
#######################################
link_log() {
  local source target
  source="$1"
  target="/silo/log/ansible.log"

  # change to the working directory, so relative log file paths will work, e.g.
  # ./ansible.log
  cd /home/user/playbooks || exit

  # Create new ansible logfile if it does not yet exists (dir might be mounted
  # from host system)
  if [[ ! -f "${source}" ]]; then
    mkdir -p "$(dirname "${source}")"
    touch "${source}"
    chmod 666 "${source}"
  fi

  if [[ "${source}" != "${target}" ]]; then
    ln -s "$(realpath "${source}")" "${target}"
  fi

  # ANSIBLE_LOG_PATH is used by Ansible to define log file location
  export ANSIBLE_LOG_PATH="${target}"
}

#######################################
# Re-creates user inside the container matching name and ID of the user
# invoking the container. Puts .ssh/config into place as it was mounted from
# the users home directory
# Globals:
#   HOME
#   USER_ID
#   USER_NAME
# Arguments:
#   None
# Returns:
#   None
#######################################
prepare_user() {
  local ssh_conf_orig ssh_conf_new

  # USER_NAME and USER_ID are passed as environment vars in the docker-run
  # command.
  if [[ -z "${USER_NAME}" ]]; then
    echo "\$USER_NAME must be provided" >&2
    exit "${EX_USER}"
  fi

  if [[ -z "${USER_ID}" ]]; then
    echo "\$USER_ID must be provided" >&2
    exit "${EX_USER}"
  fi

  if [[ "${USER_ID}" -eq "0" ]]; then
    echo "You can't run silo as root!" >&2
    exit "${EX_USER}"
  fi

  # We manually create the user by writing to files `adduser` will not always
  # work. By default `adduser` only accepts UIDs between 0..256000. This limit
  # can be increased but it still will not create users if the ID is in the
  # reserved range for user management tools such as LDAP. If the user
  # originally was created through LDAP, it can not be created with the same ID
  # inside the container.
  echo "${USER_NAME}:x:${USER_ID}:" >> /etc/group
  echo "${USER_NAME}:x:${USER_ID}:${USER_ID}:Linux" \
    "User,,,:/home/user:/bin/bash" >> /etc/passwd
  echo "${USER_NAME}    ALL=NOPASSWD: ALL" >> /etc/sudoers
  chown "${USER_ID}" /home/user /silo/log
  export HOME=/home/user

  if [[ ! -d "${HOME}/.ssh" ]]; then
    return
  fi

  # If the user has no known_hosts file, create it. Otherwise we would not have
  # a symlink later, but an actual file in .ssh, which will be lost after the
  # current ansible run
  if [[ ! -e "${HOME}/._ssh/known_hosts" ]]; then
    touch "${HOME}/._ssh/known_hosts"
    chown -R "${USER_ID}" "${HOME}/._ssh/known_hosts"
  fi

  ln -s "${HOME}"/._ssh/* "${HOME}/.ssh" > /dev/null 2>&1
  ssh_conf_orig="${HOME}/._ssh/config"
  ssh_conf_new="${HOME}/.ssh/config"
  if [[ -f "${ssh_conf_orig}" ]]; then
    rm -f "${ssh_conf_new}"
    # We remove any occurrence of ControlPath from the ssh config, as the
    # location might not be available inside the silo container. Furthermore
    # the ControlPath is defined in the global ssh config.
    sed '/^ControlPath/d' "${ssh_conf_orig}" > "${ssh_conf_new}"
  fi
  chown -R "${USER_ID}" "${HOME}/.ssh"
}

#######################################
# Sets up user environment
# Globals:
#   PATH
# Arguments:
#   None
# Returns:
#   None
#######################################
prepare_environment() {
  export PATH="/silo/userspace/bin:${PATH}"
}

#######################################
# Run any given command as user $USER_NAME
# Globals:
#   USER_NAME
# Arguments:
#   Command to run
# Returns:
#   None
#######################################
run_as_user() {
  exec /usr/bin/gosu "${USER_NAME}" "$@"
}

#######################################
# Run any given command as user $USER_NAME with SSH support
# Globals:
#   None
# Arguments:
#   Command to run
# Returns:
#   None
#######################################
run_as_user_with_SSH() {
  # shellcheck disable=SC2016
  # We use single quotes intentionally, as this string should not be expanded
  local command='if ! ssh-add -l > /dev/null 2>&1; then
                   eval $(ssh-agent) > /dev/null
                   ssh-add
                 fi;'
  for var in "$@"; do
    command+=" \"${var}\""
  done
  run_as_user bash -c "${command}"
}

#######################################
# Print all available git tags from the Ansible repository on github
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
get_ansible_tags() {
  echo "List of available tags:"
  git tag --list | grep -vE "rc|alpha|beta" | sed 's/^/  /'
}

#######################################
# Print current ansible version
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
get_ansible_version() {
  ansible-playbook --version \
    | grep ansible-playbook \
    | sed 's/[^0-9.]*\([0-9.]*\).*/\1/'
}

#######################################
# Switch Ansible to a given git tag, branch or commit ID
# Globals:
#   None
# Arguments:
#   git tag, branch or commit ID to switch to
# Returns:
#   None
#######################################
switch_ansible_version() {
  cd /silo/userspace/ansible || exit
  find . -name "*.pyc" -delete
  rm -rf v2/ansible/modules/core v2/ansible/modules/extras \
    lib/ansible/modules/core lib/ansible/modules/extras
  if ! git fetch --quiet; then
    echo "Failed to fetch!" >&2
    exit "${EX_GFETCH}"
  fi

  if [[ -z "$1" ]]; then
    echo "Please provide a valid git branch or tag from the Ansible" \
      "repository." >&2
    get_ansible_tags
    exit "${EX_VERSION}"
  fi

  if ! git checkout -f "$1" --quiet; then
    echo "Failed to switch!" >&2
    get_ansible_tags
    exit "${EX_GCHECKOUT}"
  fi

  if ! git submodule update --init --recursive --quiet; then
    echo "Failed to update submodules!" >&2
    exit "${EX_GSUB}"
  fi

  # If we're on a branch, we want to pull the latest commits. Will fail if we
  # checked out a tag
  sudo git pull > /dev/null 2>&1

  if [[ "$2" != "silent" ]]; then
    prepare_user
    prepare_ansible
    echo "Switched to Ansible $(get_ansible_version)"
  fi
}

#######################################
# Renders a template. Replaces a fixed set of placeholds with their
# corresponding values
# Globals:
#   ANSIBLE_VERSION
#   BUNDLE_IMAGE
#   BUNDLE_IMAGE_SHORT
#   BUNDLE_VERSION
#   SILO_IMAGE
#   SILO_IMAGE_SHORT
#   SILO_VERSION
# Arguments:
#   Template source file
#   Target destination
# Returns:
#   None
#######################################
render_template() {
  local template runner_functions bundle_safe

  if [[ ! -f "$1" ]]; then
    echo "File $1 does not exists or is not a file" >&2
    exit "${EX_NOINPUT}"
  fi

  template="$(< "$1")"
  if [[ "${template}" == *"{{ RUNNER_FUNCTIONS }}"* ]]; then
    runner_functions="$(< /silo/runner_functions.sh)"

    # If bundle_extension.sh exist (=this is a bundle), we also attache the
    # contents of that file.
    if [[ -f "/silo/bundle_extension.sh" ]]; then
      runner_functions+=$'\n'
      runner_functions+="$(< /silo/bundle_extension.sh)"
    fi

    template="${template//{{ RUNNER_FUNCTIONS \}\}/${runner_functions}}"
  fi

  if [[ "${template}" == *"{{ EXIT_CODES }}"* ]]; then
    exit_codes="$(< /silo/exit_codes.sh)"
    template="${template//{{ EXIT_CODES \}\}/${exit_codes}}"
  fi

  # ANSIBLE_VERSION is an environment var defined in the Dockerfile and
  # specifies which Ansible version is running by default in the container.
  if [[ -n "${ANSIBLE_VERSION}" ]]; then
    template="${template//{{ ANSIBLE_VERSION \}\}/${ANSIBLE_VERSION}}"
  else
    echo "ANSIBLE_VERSION not set" >&2
    exit "${EX_MISSINGC}"
  fi

  # SILO_VERSION is set as buld parameter "v" in docker-build.
  if [[ -n "${SILO_VERSION}" ]]; then
    template="${template//{{ SILO_VERSION \}\}/${SILO_VERSION}}"
  else
    echo "SILO_VERSION not set" >&2
    exit "${EX_MISSINGC}"
  fi

  # SILO_IMAGE is defined in silo/runner_functions.sh and contains the name
  # of the Docker image, including the repository path.
  if [[ -n "${SILO_IMAGE}" ]]; then
    template="${template//{{ SILO_IMAGE \}\}/${SILO_IMAGE}}"
  else
    echo "SILO_IMAGE not set" >&2
    exit "${EX_MISSINGC}"
  fi

  # SILO_IMAGE_SHORT is defined in silo/runner_functions.sh and contains the
  # basename of the Docker image.
  if [[ -n "${SILO_IMAGE_SHORT}" ]]; then
    template="${template//{{ SILO_IMAGE_SHORT \}\}/${SILO_IMAGE_SHORT}}"
  else
    echo "SILO_IMAGE_SHORT not set" >&2
    exit "${EX_MISSINGC}"
  fi

  # BUNDLE_IMAGE is defined in silo/bundle/Dockerfile and contains the name of
  # the bundle Docker image, including the repository path.
  if [[ -n "${BUNDLE_IMAGE}" ]]; then
    template="${template//{{ BUNDLE_IMAGE \}\}/${BUNDLE_IMAGE}}"
  fi

  # BUNDLE_IMAGE_SHORT is defined in silo/entrypoint and contains the basename
  # of the bundle Docker image.
  # BUNDLE_IMAGE_SHORT_SAFE is a safe version, replacing problematic characters
  # in bundle names.
  if [[ -n "${BUNDLE_IMAGE_SHORT}" ]]; then
    bundle_safe=$(safe_string "${BUNDLE_IMAGE_SHORT}")
    template="${template//{{ BUNDLE_IMAGE_SHORT \}\}/${BUNDLE_IMAGE_SHORT}}"
    template="${template//{{ BUNDLE_IMAGE_SHORT_SAFE \}\}/${bundle_safe}}"
  fi

  # BUNDLE_VERSION is set as buld parameter "v" in docker-build of the bundle.
  if [[ -n "${BUNDLE_VERSION}" ]]; then
    template="${template//{{ BUNDLE_VERSION \}\}/${BUNDLE_VERSION}}"
  fi

  template="${template//{{ \"{{\" \}\}/{{}"
  echo "${template}" > "$2"
}

#######################################
# Print version info for ansible, ansible-lint, silo and the current silo
# volume
# Globals:
#   BUNDLE_VERSION
#   SILO_VERSION
#   SILO_VOLUME
# Arguments:
#   None
# Returns:
#   None
#######################################
get_silo_info() {
  prepare_user
  prepare_ansible
  prepare_environment

  # If this is a bundle, a version might have been specified
  if [[ -n "${BUNDLE_VERSION}" ]]; then
    echo "${SILO_IMAGE_SHORT} ${BUNDLE_VERSION}"
  fi

  # Show the version of the silo image
  # SILO_VERSION is an environment var, set as buld parameter "v" in
  # docker-build.
  echo "ansible-silo ${SILO_VERSION}"

  # Show Ansible version
  echo "ansible $(get_ansible_version)"

  # Show ansible-lint version
  if [[ "${SILO_IMAGE_SHORT}" == "ansible-silo" ]]; then
    ansible-lint --version
  fi

  # If Ansible was installed on a Docker volume, show the volume name/location.
  # SILO_VOLUME can be set by the user to point to a specific volume where
  # ansible was installed.
  if [[ -n "${SILO_VOLUME}" ]]; then
    echo "ansible installed on volume ${SILO_VOLUME}"
  fi
}

#######################################
# Creates a silo bundle
# volume
# Globals:
#   BUNDLE_IMAGE
#   BUNDLE_IMAGE_SHORT
# Arguments:
#   Name of the bundle
# Returns:
#   None
#######################################
bundle_create() {
  local BUNDLE_IMAGE="$1"

  prepare_user
  prepare_ansible
  while true; do
    if [[ "${BUNDLE_IMAGE}" =~ ^[a-zA-Z0-9_./-]+$ ]]; then
      break
    else
      echo "Invalid bundle name: ${BUNDLE_IMAGE} - Can only contain" \
        "alphanumeric characters, underscore, hyphen, slash and dot." >&2
      read -r -p "Bundle name: " BUNDLE_IMAGE
    fi
  done

  readonly BUNDLE_IMAGE_SHORT="${BUNDLE_IMAGE##*/}"
  readonly bundle_location="/home/user/playbooks/${BUNDLE_IMAGE_SHORT}"
  if [[ -d "${bundle_location}" || -f "${bundle_location}" ]]; then
    echo "${BUNDLE_IMAGE_SHORT} already exists" >&2
    exit "${EX_CANTCREAT}"
  fi

  render_template "/silo/bundle/Dockerfile" "/silo/bundle/Dockerfile"
  render_template "/silo/bundle/build" "/silo/bundle/build"
  render_template "/silo/bundle/README.md" "/silo/bundle/README.md"
  render_template "/silo/runner" "/silo/runner"
  render_template "/silo/bundle/bin/starter" "/silo/bundle/bin/starter"
  render_template "/silo/bundle/bundle_extension.sh"\
    "/silo/bundle/bundle_extension.sh"
  mv "/silo/bundle/bin/starter" "/silo/bundle/bin/${BUNDLE_IMAGE_SHORT}"
  run_as_user cp -R "/silo/bundle" "${bundle_location}"
}

#######################################
# Render the runner script and print the command to invoke it
# volume
# Globals:
#   SILO_VERSION
# Arguments:
#   $@ - everything that was passed to ansible-silo
# Returns:
#   None
#######################################
create_runner() {
  local command runner_path var version

  render_template "/silo/runner" "/runner"
  version="${BUNDLE_VERSION:-${SILO_VERSION}}"
  runner_path="/tmp/${SILO_IMAGE_SHORT}-runner-${version}"
  if [[ ! -f "${runner_path}" ]]; then
    mv "/runner" "${runner_path}"
    chmod +x "${runner_path}"
  else
    rm "/runner"
  fi
  command="${runner_path}"
  shift
  for var in "$@"; do
    command+=" \"${var}\""
  done
  echo "${command}"
}

#######################################
# Replaces unsafe characters in a string. Only alphanumeric characters, _
# and . are allowed. Other characters will be replaces with underscores.
# Globals:
#   BASH_REMATCH
# Arguments:
#   string to clean up
# Returns:
#   Input string with replaces characters
#######################################
safe_string() {
  local string="$1"
  while [[ $string =~ (.*)[^A-Za-z0-9._]+(.*) ]]; do
    string=${BASH_REMATCH[1]}_${BASH_REMATCH[2]}
  done
  echo "$string"
}
