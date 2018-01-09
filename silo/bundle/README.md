Silo bundle {{ BUNDLE_IMAGE_SHORT }}
====================================

This is a [silo](https://github.com/groupon/ansible-silo) bundle. This means this folder contains all files required to build a Docker image based on Ansible Silo.

Add your custom playbooks, roles, Ansible configuration etc. into the `./playbooks` folder.

Custom pre-build steps, like installing Galaxy roles, can be added to the `./build` script. Installing Galaxy roles from private git repos can not be done through `./Dockerfile` inside the building image, since this would require a forwarded ssh socket inside the container, which is not possible during the build process.

If additional software is required by the playbooks, you can modify `./Dockerfile`. Silo is based on Alpine Linux, so you can install apk's from their [repo](https://pkgs.alpinelinux.org/packages).

To build a docker image out of your bundle, run the `./build` script.

To install an executable starter script for your bundle run:

```bash
docker run -it --rm -v "$HOME/bin:/silo_install_path" -i {{ BUNDLE_IMAGE }}:latest --install
```

Now you'll be able to simply call `{{ BUNDLE_IMAGE_SHORT }}` to execute your playbooks.

If you have the need to inject additional parameters into the docker call to {{ BUNDLE_IMAGE_SHORT }} like mounting additional docker volumes or passing in environment variables you can do this in two ways:

1. In the bundle: Add custom functions to the file `./bundle_extension.sh`.

2. On the host: Add functions in either `/etc/ansible/ansible-silo/{{ BUNDLE_IMAGE_SHORT }}` or `$HOME/.{{ BUNDLE_IMAGE_SHORT }}`.

All contained bash functions matching the pattern `{{ BUNDLE_IMAGE_SHORT }}_*` will be executed and their return value (`echo`) will be appended to the docker command.


# Description of files

## build

A bash script to trigger the build process. This is where you can add pre-build steps.

Execute this script to build your Docker image.


## bundle_extension.sh

A placeholder file which can be filled with custom functions. Functions starting with `silo_*` or `{{ BUNDLE_IMAGE_SHORT }}_*` will be executed and their return value (`echo`) will be appended to the docker command which invokes the container. For example this can be used to mount additional volumes. See [this file](https://github.com/groupon/ansible-silo/blob/master/silo/runner_functions.sh) for examples.


## Dockerfile

Docker build instructions of your bundle.

Here you should set (and update) your bundle version defined per `ENV BUNDLE_VERSION`

If you define a `ANSIBLE_VERSION` you can enforce a specific ansible version:

```
ENV ANSIBLE_VERSION v2.1.1.0-1
RUN /silo/entrypoint --switch "${ANSIBLE_VERSION}" silent
```

A version has to match a git tag, branch or commit ID of the [Ansible github repository](https://github.com/ansible/ansible).


## entrypoint

This script gets called when your container is started. This is where all the available options are covered. Extend this script to add further functionality.

The pre-defined options are:

- `--version`: Display Bundle, Silo & Ansible version
- `--install`: Installs the `.bashrc` alias. Needs to be called as `docker run -it --rm -v "$HOME:/home/user" -i {{ BUNDLE_IMAGE }}:latest --install`
- `--run`: The _run_ section in combination with the `./runner` file describes how the bundle is going to be invoked. Silo calls can get complicated due to the vast amount of forwarded variables (e.g. user name, user ID) and mounted volumes (e.g. ssh config). What needs to be forwarded/mounted depends on a bundle. Therefore a bundle can be called with the `--run` option to describe itself. The returned command gets again executed on the host. See also the [silo readme](https://github.com/groupon/ansible-silo#how-it-works) for more information.
- `--shell`: Opens a bash shell inside the container. This is mostly implemented for debugging purpose and can be removed if you feel you do not need it in your bundle

Everything not matching one of the above options will be forwarded to `ansible-playbook` in the last _case_ path. This is where you can fine-tune how `ansible-playbook` is called. The default functionality is to simply call `ansible-playbook` and forward all parameters as they were given when the container was started:


```bash
    *)
        prepare_user
        prepare_ansible
        cd /home/user/playbooks || exit
        run_as_user_with_SSH "/silo/userspace/ansible/bin/ansible-playbook" "$@"
    ;;
```

If you only have a single playbook in your bundle and want to hardcode it, this is where you would do it:

```bash
    *)
        prepare_user
        prepare_ansible
        cd /home/user/playbooks || exit
        run_as_user_with_SSH "/silo/userspace/ansible/bin/ansible-playbook" "playbook.yml"
    ;;
```


## playbooks

This folder contains a dummy playbook, ansible configuration and inventory file. This is where you put your custom playbooks etc.


# Description of silo functions

Silo provides [a set of pre-defined function](https://github.com/groupon/ansible-silo/blob/master/silo/silo_functions.sh) you can use in your `entrypoint`. You can see how these functions are utilized in silos own [`entrypoint`](https://github.com/groupon/ansible-silo/blob/master/silo/entrypoint).


## prepare_ansible

This method has to be called before running ansible. The function will trigger the ansible setup script and takes care of setting a default log path. (`/var/log/ansible.cfg`)


## prepare_user

This method has to be called before you run something in context of the user. It creates a user with the same name and ID as the user who started the container.


## run_as_user

Executes given command as the user who started the container. The function `prepare_user` has to be called before.

```bash
run_as_user "whoami"
```


## run_as_user_with_SSH

Executes given command as the user who started the container. The function `prepare_user` has to be called before.

This also ensures there is a valid forwarded ssh-agent/socket from the host. If you want to run a command in context of the user which utilizes ssh, use this function.

If there was no valid forwarded ssh-agent/socket, it will be tried to start a new ssh-agent and all configured keys will be added. In case the user has password protected ssh keys he will be prompted for those passwords.

```bash
run_as_user_with_SSH "whoami"
```

<sub>This basically is a workaround to overcome the bug [#410 of Docker for Mac](https://github.com/docker/for-mac/issues/410).</sub>


## switch_ansible_version

This function can be used to switch to any Ansible version by providing a git tag, branch or commit ID.

```bash
switch_ansible_version "devel"
```

```bash
switch_ansible_version "v2.1.1.0-1"
```


## render_template

Takes a source and a destination path. The source will be loaded, all occurrences of below placeholders will be replaced and finally written to the destination path. Source and destination may be the same.

 - `{{ "{{" }} RUNNER_FUNCTIONS }}`: Content of the file [`runner_functions.sh`](https://github.com/groupon/ansible-silo/blob/master/silo/runner_functions.sh)
 - `{{ "{{" }} ANSIBLE_VERSION }}`: ENV var as defined in the `Dockerfile`. If you have not defined this ENV in your `Dockerfile` the setting from the parent silo image will be used.
 - `{{ "{{" }} SILO_VERSION }}`: Version of silo
 - `{{ "{{" }} SILO_IMAGE }}`: Complete path of the docker image (including registry) as defined in the Dockerfile
 - `{{ "{{" }} SILO_IMAGE_SHORT }}`: Name of the docker image. This is derived from `SILO_IMAGE`
 - `{{ "{{" }} BUNDLE_IMAGE }}`: Complete path of the bundle docker image.
 - `{{ "{{" }} BUNDLE_IMAGE_SHORT }}`: Name of the bundle docker image. This is derived from `BUNDLE_IMAGE`

```bash
render_template /path/to/src /path/to/dst
```


## get_silo_info

This method shows all available info about ansible-silo:

 - Version of your bundle (as defined in the `Dockerfile` per `BUNDLE_VERSION`
 - ansible-silo version
 - ansible version
 - ansible-lint version

```
{{ BUNDLE_IMAGE_SHORT }} 1.2.3
ansible-silo {{ SILO_VERSION }}
ansible {{ ANSIBLE_VERSION }}
ansible-lint 3.4.13
```


# License

    Copyright (c) 2017, Groupon, Inc.
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:

    Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

    Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

    Neither the name of GROUPON nor the names of its contributors may be
    used to endorse or promote products derived from this software without
    specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
    IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
    PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
    TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
    NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
