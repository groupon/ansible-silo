#!/usr/bin/env bash
#
# runner functions which will be used by the runner scripts of ansible-silo and
# all its bundles.
#
# Functions in this file will be available in the runner scripts of silo AND
# child images of silo. Functions starting with _silo_* will be executed and
# their output will be appended to the docker starting command of silo.
# Functions starting with silo_* will be executed and their output will be
# appended to the docker starting command of silo and its child images.
#
# The file ~/.ansible-silo will be sourced, so the user additionally can define
# custom functions
# For child images additionally the file ~/.$IMAGE_NAME will be sourced, e.g.
# for an image named foo-bar the file ~/.foo-bar will be loaded and all
# functions starting with silo_* and foo_bar* will be loaded
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

#{{ EXIT_CODES }}

# SILO_IMAGE, SILO_IMAGE_SHORT and SILO_VERSION are replaced with their values
# when the runner file is copied to the host. SILO_IMAGE is defined in
# Dockerfile. SILO_IMAGE_SHORT is defined in silo/silo_functions.sh.
# SILO_VERSION is defined in silo/bin/ansible-silo but can be overridden by the
# user through environment var
readonly SILO_IMAGE="{{ SILO_IMAGE }}"
readonly SILO_IMAGE_SHORT="{{ SILO_IMAGE_SHORT }}"
readonly SILO_VERSION="{{ SILO_VERSION }}"

#######################################
# Forwards the name and UID of the user starting the container into the
# container
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   --env options for USER_NAME and USER_ID
#######################################
silo_user_forwarding() {
  local my_name my_id return=""

  my_name="$(whoami)"
  my_id="$(id -u "${my_name}")"

  return+="--env USER_NAME=\"${my_name}\" "
  return+="--env USER_ID=\"${my_id}\""
  echo "${return}"
}

#######################################
# Mounts users ssh config directory
# Globals:
#   HOME
# Arguments:
#   None
# Returns:
#   --volume for mounting ~/.ssh
#######################################
silo_ssh_config() {
  local my_ssh_dir

  if [[ -d "${HOME}/.ssh" ]]; then
    my_ssh_dir="$(cd ~/.ssh && pwd -P)"
    echo "--volume \"${my_ssh_dir}:/home/user/._ssh\""
  fi
}

#######################################
# Mounts location of a potentially forwarded ssh key and forwards the
# SSH_AUTH_SOCK env var
# As socket forwarding is still not supported on Docker 4 Mac, this function
# has support for pinata-ssh-mount. See:
# https://github.com/groupon/ansible-silo/issues/2
# Globals:
#   SSH_AUTH_SOCK
# Arguments:
#   None
# Returns:
#   --env and --volume options for mounting and forwarding the SSH_AUTH_SOCK
#######################################

silo_ssh_key_forwarding() {
  local auth_sock_link_dir auth_sock_dir forwarding_status return=""

  if command -v pinata-ssh-mount >/dev/null 2>&1; then
    forwarding_status=$(docker inspect -f "{{.State.Running}}" pinata-sshd)
    if [[ "$forwarding_status" == "true" ]]; then
      return=$(pinata-ssh-mount)
    fi
  else
    if [[ ! -z "${SSH_AUTH_SOCK}" ]]; then
      if [[ -L "${SSH_AUTH_SOCK}" ]]; then
        auth_sock_link_dir="$(dirname "$(cd "${SSH_AUTH_SOCK}" && pwd -P)")"
        return+="--volume \"${auth_sock_link_dir}\":\"${auth_sock_link_dir}\" "
      fi
      auth_sock_dir="$(dirname "${SSH_AUTH_SOCK}")"
      return+="--volume \"${auth_sock_dir}\":\"${auth_sock_dir}\" "
      return+="--env SSH_AUTH_SOCK"
    fi
  fi

  echo "${return}"
}

#######################################
# Sets the hostname of the container
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   --hostname option
#######################################
silo_hostname() {
  echo "--hostname \"silo.$(hostname -f)\""
}

#######################################
# Forwards all environment and local variables to the container, except those
# defined in the filter
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   --env options for forwarding all available env vars
#######################################
_silo_var_forwarding() {
  local var_filter var_filter_item var return=""

  var_filter=("_" "_fzf_"* "BASH"* "command" "EDITOR" "func" "FUNCNAME" "FZF"*
    "GROUPS" "HOME" "HOSTNAME" "i" "ID" "IFS" "LOGNAME" "LS_COLORS" "MACHTYPE"
    "OLDPWD" "OSTYPE" "PATH" "SILO_"* "PWD" "return" "SHELL" "SSH_"* "TERM"
    "TMPDIR" "UID" "USER" "var" "var_filter" "var_filter_item" "XDG_"* "EX_"*
    "GIT_"*)
  for var in $( (set -o posix; set) | grep = | cut -d '=' -f 1 ); do
    for var_filter_item in "${var_filter[@]}"; do
      # shellcheck disable=SC2053
      if [[ "${var}" == ${var_filter_item} ]]; then
        continue 2
      fi
    done
    return+="--env ${var} "
  done
  echo "${return}"
}

#######################################
# Mounts default silo volume. If volume does not exist, it will be created.
# Globals:
#   SILO_VOLUME
# Arguments:
#   None
# Returns:
#   --env and --volume options for mounting the silo volume
#######################################
_silo_volume() {
  local return=""

  # SILO_VOLUME can be set by the user to point to a specific volume where
  # ansible was/will be installed. It defaults to a volume named after the
  # user.
  SILO_VOLUME="silo.${SILO_VOLUME:-$(whoami)}"

  if ! docker volume inspect "${SILO_VOLUME}" > /dev/null 2>&1; then
    if ! docker volume create --name "${SILO_VOLUME}" > /dev/null; then
      echo "Failed to create docker volume ${SILO_VOLUME}" >&2
      exit "${EX_DVOLUME}"
    fi
  fi
  return+="--volume \"${SILO_VOLUME}:/silo/userspace\" "
  return+="--env \"SILO_VOLUME=${SILO_VOLUME}\""
  echo "${return}"
}

#######################################
# Mounts current working directory as playbooks directory
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   --volume option for mounting the current PWD as volume
#######################################
_silo_mount_playbooks() {
  local pwd
  pwd="$(pwd -P)"
  echo "--volume \"${pwd}:/home/user/playbooks\""
}

#######################################
# Checks if a log file is configured per environemnt var or inside ansible.cfg.
# If a file is configured it will be mounted into the container.
# Globals:
#   ANSIBLE_LOG_PATH
# Arguments:
#   None
# Returns:
#   --volume and --env options for setting the logfile
#######################################
silo_mount_logfile() {
  local config logdir logfile log_path pwd return=""

  # If logfile if defined in environment var
  if [[ -n "${ANSIBLE_LOG_PATH}" ]]; then
    logfile="${ANSIBLE_LOG_PATH}"
  # If logfile if defined inside ansible.cfg
  else
    pwd="$(pwd -P)"
    config="${pwd}/ansible.cfg"
    if [[ -f "${config}" ]]; then
      if grep -q "^log_path\\s*=" "${config}"; then
        # shellcheck disable=SC1090
        source <(grep log_path "${config}" | sed 's/ *= */=/g')
        logfile="${log_path}"
      fi
    fi
  fi

  if [[ -n "${logfile}" ]]; then
    logfile="$(realpath "${logfile}")"
    logdir="$(dirname "${logfile}")"
    return+="--volume '${logdir}:${logdir}' "
    return+="--env \"ANSIBLE_LOG_PATH=${logfile}\""
    echo "${return}"
  fi
}

#######################################
# Mounts docker socket
# Globals:
#   SILO_NO_PRIVILEGED
# Arguments:
#   None
# Returns:
#   --volume and --privileged options for mounting docker socket
#######################################
silo_mount_docker_socket() {
  local docker_socket check_paths

  # SILO_NO_PRIVILEGED may be set by the user to prevent the container to
  # run in privileged mode. As a result this disables forwarding of the docker
  # socket
  if [[ ! -z "${SILO_NO_PRIVILEGED}" ]]; then
    return
  fi

  check_paths=("/var/run/docker.sock" "/private/var/run/docker.sock")
  for docker_socket in "${check_paths[@]}"; do
    if [[ -S "/var/run/docker.sock" ]]; then
      echo "--volume ${docker_socket}:/var/run/docker.sock --privileged"
      break
    fi
  done
}

#######################################
# Mounts location of ANSIBLE_VAULT_PASSWORD_FILE, if set
# Globals:
#   ANSIBLE_VAULT_PASSWORD_FILE
# Arguments:
#   None
# Returns:
#   --volume and --env options for mounting/rewriting location of password file
#######################################
silo_forward_vault_password_file() {
  local vault_password_dir return=""
  if [[ ! -z "${ANSIBLE_VAULT_PASSWORD_FILE}" ]]; then
    vault_password_dir="$(dirname "${ANSIBLE_VAULT_PASSWORD_FILE}")"
    return+="--volume \"${vault_password_dir}\":"
    return+="\"/tmp/${vault_password_dir}:ro\" "
    return+="--env ANSIBLE_VAULT_PASSWORD_FILE="
    return+="\"/tmp/${ANSIBLE_VAULT_PASSWORD_FILE}\""
    echo "${return}"
  fi
}

# Load any potential silo extensions
# The files ~/.ansible-silo and /etc/ansible/ansible-silo/ansible-silo are
# going to be loaded in any case. If the container is a child of silo,
# additionally the files matching the image name will be loaded
if [[ "${SILO_IMAGE_SHORT}" != "ansible-silo" ]]; then
  if [[ -f "/etc/ansible/ansible-silo/ansible-silo" ]]; then
    # shellcheck disable=SC1091
    source "/etc/ansible/ansible-silo/ansible-silo"
  fi
  if [[ -f "${HOME}/.ansible-silo" ]]; then
    # shellcheck disable=SC1090
    source "${HOME}/.ansible-silo"
  fi
fi
if [[ -f "/etc/ansible/ansible-silo/${SILO_IMAGE_SHORT}" ]]; then
  # shellcheck disable=SC1090
  source "/etc/ansible/ansible-silo/${SILO_IMAGE_SHORT}"
fi
if [[ -f "${HOME}/.${SILO_IMAGE_SHORT}" ]]; then
  # shellcheck disable=SC1090
  source "${HOME}/.${SILO_IMAGE_SHORT}"
fi

# If an .ansible-silo file exists in the current working directory, load it
if [[ -f ".${SILO_IMAGE_SHORT}" ]]; then
  # shellcheck disable=SC1090
  source ".${SILO_IMAGE_SHORT}"
fi
