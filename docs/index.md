---
title: Ansible Silo
asciinema: true
---

[![GitHub release](https://img.shields.io/github/tag/groupon/ansible-silo.svg?style=flat&colorB=4183C4&label=Latest%20release)](https://github.com/groupon/ansible-silo/releases/latest)
[![Commits since v2.2.0](https://img.shields.io/github/commits-since/groupon/ansible-silo/v2.2.0.svg?style=flat&colorB=4183C4&label=Commits%20since%20v2.2.0)](https://github.com/groupon/ansible-silo/commits/master)
[![GitHub Stars](https://img.shields.io/github/stars/groupon/ansible-silo.svg?style=flat&colorB=4183C4&label=GitHub%20Stars)](https://github.com/groupon/ansible-silo/stargazers)
[![Build Status](https://img.shields.io/travis/groupon/ansible-silo.svg?style=flat&label=Tests)](https://travis-ci.org/groupon/ansible-silo)
[![Docker Build Status](https://img.shields.io/docker/automated/grpn/ansible-silo?style=flat&label=Build)](https://hub.docker.com/r/grpn/ansible-silo/builds/)
[![Code Climate](https://codeclimate.com/github/groupon/ansible-silo/badges/gpa.svg)](https://codeclimate.com/github/groupon/ansible-silo)

If you expect reproducible outcome of an automation system, you not only need to make sure you have a specific version of the automation system itself, but also have fixed versions of all its dependencies. The most prominent Ansible dependency which can affect your plays would be Jinja2 but this applies to all involved components.

Silo not only removes moving parts by having 100% fixed dependencies hardcoded in a Docker image. It also enables you to switch Ansible to any version without affecting other users, therefore making it easy to test your playbooks and roles against new Ansible releases and run differing Ansible versions per playbook, project or user.

Furthermore you can bundle your playbooks (incl. configuration, roles, plugins etc) in a custom Docker image which inherits Silo and therefore generate a versioned, shippable, complete and self-contained executable package which runs your playbooks in any environment. (where you have access to a Docker daemon)

For convenience ansible-silo includes [ansible-lint]. Since ansible-lint uses the Ansible libraries it may react differently depending on the used Ansible version.

## Demo

<asciinema-player src="asciicasts.json" poster="npt:0:32" title="ansible-silo demo" theme="asciinema" author="Groupon" preload="true" cols="143" rows="39"></asciinema-player>
<p class="asciinema-credit">This recording is powered by <a href="https://github.com/asciinema/asciinema-player">asciinema player</a> and <a href="https://github.com/paxtonhare/demo-magic">demo-magic</a>.</p>

## What problem does Silo solve?

If you expect reproducible outcome of an automation system, you not only need to make sure you have a specific version of the automation system itself, but also have fixed versions of all its dependencies. The most prominent Ansible dependency which can affect your plays would be Jinja2 but this applies to all involved components.

One approach to solve above problem are shared control hosts. Control hosts though add another problem: All teams and users who use the Ansible control hosts need to align on one specific Ansible version and it gets extremely complicated to update Ansible on the control hosts since all teams and users need to align and test all their roles and playbooks against the new version.

Silo not only removes moving parts by having 100% fixed dependencies hardcoded in a Docker image. It also enables you to switch Ansible to any version without affecting other users, therefore making it easy to test your playbooks and roles against new Ansible releases and run differing Ansible versions per playbook, project or user.


## How it works

Silo bundles Ansible and all its dependencies in a Docker image.

To enable Ansible in the container to connect to remote hosts, your `~/.ssh` folder is mounted and also, if available, your ssh auth socket (key forwarding) is mounted.

Starting the Silo container is a complex Docker command which needs to cover forwarding of environment variables and mounting required resources like the users ssh configuration. This complex command itself is included in the image and can be fetched by starting the container with the `--run` flag. The returned command then can be executed on the host which will start the container again with the correct parameters.

![Sequence diagram](sequence-diagram.jpg)

A [bash script](https://github.com/groupon/ansible-silo/blob/master/silo/bin) to easily trigger this process [can automatically be installed](#install-ansible-silo) by Silo when called with the `--install` flag.

The Silo container is not persistent, not running in the background. A new container is started for every Ansible call and is automatically removed after completion.


### Standalone mode

Standalone mode means you run Silo as a replacement for Ansible. By default Ansible is installed in a Docker volume. The volume can be changed, so you can have multiple volumes with different Ansible versions, e.g. per user, per environment or per playbook.

Playbooks will be mounted from the local file system and are not part of Silo.


### Bundle mode

A bundle is a Docker image which inherits the Silo Docker image.

In the bundle you can add your playbooks, roles, configuration and a specific Ansible version to the bundle.

A new bundle can easily be created by calling Silo with `--bundle <bundle name>` option.


## Included software

Silo is based on **[Alpine Linux] 3.6** and includes the following APK packages:

 - bash 4.3.48-r1
 - ca-certificates 20161130-r2
 - curl 7.55.0-r0
 - expat 2.2.0-r1
 - gdbm 1.12-r0
 - git 2.13.5-r0
 - gmp 6.1.2-r0
 - gosu 1.9-r0
 - libbz2 1.0.6-r5
 - libcurl 7.55.0-r0
 - libffi 3.2.1-r3
 - libxml2 2.9.4-r4
 - libxslt 1.1.29-r3
 - libssh2 1.8.0-r1
 - ncurses-libs 6.0-r8
 - ncurses-terminfo 6.0-r8
 - ncurses-terminfo-base 6.0-r8
 - musl 1.1.16-r13
 - musl-utils 1.1.16-r13
 - openssh 7.5_p1-r1
 - openssh-client 7.5_p1-r1
 - openssh-sftp-server 7.5_p1-r1
 - openssl 1.0.2k-r0
 - pcre 8.41-r0
 - perl 5.24.1-r2
 - py-netifaces 0.10.5-r3
 - py2-pip 9.0.1-r1
 - readline 6.3.008-r5
 - sqlite-libs 3.18.0-r0
 - sshpass 1.06-r0
 - sudo 1.8.19_p2-r0
 - yaml 0.1.7-r0


The following Python modules are installed via pip:

 - cffi 1.10.0
 - cryptography 2.0.2
 - ecdsa 0.13
 - enum34 1.1.6
 - httplib2 0.9.2
 - idna 2.5
 - ipaddress 1.0.18
 - jinja2 2.8
 - jmespath 0.9.3
 - markupsafe 0.23
 - netaddr 0.7.19
 - paramiko 1.16.0
 - pexpect 4.2.1
 - ptyprocess 0.5.2
 - pycparser 2.18
 - pycrypto 2.6.1
 - pyyaml 3.11
 - six 1.10.0


## Installation

### Prerequisites

You need to be on a system where you have installed Docker (minimum version 1.9).


### Install ansible-silo

To install the `ansible-silo` executable along with Ansible replacements run:

```bash
docker run --interactive --tty --rm --volume "$HOME/bin:/silo_install_path" grpn/ansible-silo:2.2.0 --install
```

This command mounts your `~/bin` directory so Silo can place its executables there. Select any location you like but make sure it is in your `$PATH`.

To install `ansibe-silo` for all users you can mount `/usr/local/bin`:

```bash
docker run --interactive --tty --rm --volume "/usr/local/bin:/silo_install_path" grpn/ansible-silo:2.2.0 --install
```

### Uninstall ansible-silo

During installation two things happened:

- A Docker image was downloaded
- A file and a couple of symlinks were created

Where the files/links are stored depends on which path you have mounted during the installation process (see above, e.g. `$HOME/bin` or `/usr/local/bin`).

You can use this command to delete all files and symlinks:

```bash
find -L "$(dirname $(command -v ansible-silo))" -samefile "$(command -v ansible-silo)" -exec rm -f {} +
```

All versions of the ansible-silo images can be deleted per:

```bash
docker rmi --force $(docker images -q grpn/ansible-silo | uniq)
```


### Updating

It is important to understand, that by updating Silo you do not automatically switch the Ansible version. Ansible is stored in the Docker volume `silo.$(whoami)`. If you want to switch the Ansible version, you manually need to run the [switch](#--switch-switch-to-any-ansible-version).

This also means you do not need to pull the _latest_ version of the image to run a newer version of Ansible inside. You can run any Ansible version in any version of the Silo image.

To update the image run:

```bash
ansible-silo --update
```

This will pull the _latest_ image from the Docker registry and automatically tries to replace the ansible* executables. If these are not writable by your user you can write them to a different location and later move then with `sudo`.

```bash
mkdir /tmp/ansible
SILO_PATH=/tmp/ansible ansible-silo --update
sudo mv /tmp/ansible/* /usr/local/bin
rm -rf /tmp/ansible
```

Silo will by default run the latest installed version of itself. You also can run any other version of Silo by simply passing in the version:

```bash
SILO_VERSION=1.2.2 ansible-silo --version
ansible-silo 1.2.2
ansible 2.3.0.0
ansible-lint 3.4.20
ansible installed on volume silo.some.user
```


### Extending runner script

The Docker command which gets executed for calling Ansible is stored inside the image itself, so it cannot be modified. To inject additional parameters into the command you can define functions in `./.ansible-silo`, your `~/.ansible-silo` or globally in `/etc/ansible/ansible-silo/ansible-silo` file matching the pattern `silo_*` or `_silo_*`. The runner script will execute all `silo_*` and `_silo_*` functions and append their output to the Docker command.

For instance, if you need to mount an additional volume, you can add a method like this to your `~/.ansible-silo` file:

```bash
silo_custom_volume_mounting() {
  local VOLUME_PATH="$HOME/some/path"
  if [[ -n "$VOLUME_PATH" && -d "$VOLUME_PATH" ]]; then
    echo "--volume '$(cd "$VOLUME_PATH" && pwd -P):/tmp/custom-volume'"
  fi
}
```

In Silo bundles you can add functions to the file `bundle_extension.sh` inside your bundle directory. To customize behavior per user or host, you also have the option to add functions to files matching the image name. If, for example, you run a bundle called `foo-bar`, Silo will search for the files `./.foo-bar`, `~/.foo-bar` and `/etc/ansible/ansible-silo/foo-bar` and append the output of all functions matching the pattern `foo_bar_*` to the Docker command.

Functions matching `_silo_*` will not be included in bundle mode. Functions matching `silo_*` will.

|              | standalone | bundle |
|--------------|------------|--------|
| silo_*       | ✓          | ✓      |
| \_silo\_*    | ✓          | ✗      |
| image_name_* | ✗          | ✓      |


### Installing custom software

You can install custom software in any Silo volume. The mountpoint for Silo volumes is `/silo/userspace/`.

Inside any volume you will have a `lib` and a `bin` directory.

pip is pre-configured to install packages into the volume:

```bash
$ ansible-silo --shell pip install pbr==3.1.1
/usr/lib/python2.7/site-packages/pip/commands/install.py:194: UserWarning: Disabling all use of wheels due to the use of --build-options / --global-options / --install-options.
  cmdoptions.check_install_build_global(options)
Collecting pbr==3.1.1
  Downloading pbr-3.1.1.tar.gz (102kB)
    100% |████████████████████████████████| 112kB 7.9MB/s
Installing collected packages: pbr
  Running setup.py install for pbr ... done
Successfully installed pbr

$ ansible-silo --shell which pbr
/silo/userspace/bin/pbr
```


## Configuration

Ansible Silo can be configured per bash environment variables. Variables will also be picked up from three files (bash):

* `./.ansible-silo` (in current working directory)
* `~/.ansible-silo` (in users home directory)
* `/etc/ansible/ansible-silo/ansible-silo`

For Silo bundles also the following files will be loaded:

* `./.bundle-name`
* `~/.bundle-name`
* `/etc/ansible/ansible-silo/bundle-name`

This enables the user to define custom behavior per playbook location, per user and globally.

### List of configuration options

#### SILO_DEBUG

If defined, enables debug mode. In debug mode Silo will list all `SILO_*` env vars and the Docker command which is executed to start the Silo container.

```bash
SILO_DEBUG=true ansible-silo --shell exit
```

Which will show something along these lines:

    SILO vars:
     - SILO_DEBUG=true

    Runner file already exists.

    Executing: /tmp/ansible-silo-runner-2.2.0 "--shell" "exit"

    Executing: /usr/bin/docker run --interactive --tty --rm --volume "/home/daniel.schroeder/ansible-silo:/home/user/playbooks" --volume "silo.some.user:/silo/userspace" --env "SILO_VOLUME=silo.some.user" --hostname "silo.example.com" --volume /var/run/docker.sock:/var/run/docker.sock --privileged  --volume "/home/some.user/.ssh:/home/user/._ssh" --volume "/tmp/ssh-6k3r1bCpCi":"/tmp/ssh-6k3r1bCpCi" --env SSH_AUTH_SOCK --env USER_NAME="some.user" --env USER_ID="1234" "grpn/ansible-silo:2.2.0" "--shell" "exit"

The first _Executing_ line shows the location of the generated runner script. The last line shows the Docker command executed by the runner script.


#### SILO_DOCKER_CMD

The base Docker command that will be executed. This simply defaults to `docker`.


#### SILO_NO_PRIVILEGED

Disables [privileged mode]. Consequently will not forward the Docker socket into the container and any interaction with Docker will not work.


#### SILO_PATH

Can be used to specify a custom location where Silo starter scripts will be installed during [update](#update).

```bash
SILO_PATH=/tmp/ansible ansible-silo --update
```

#### SILO_VERSION

If set to a valid Silo version, that specific version of Silo container will be started. This does not change the installed `ansible-silo` command. Most functionality though is inside the container and not the starter script.


#### SILO_VOLUME

Specifies the name of the used Silo volume. This defaults to the name of the current user.


## Usage

### `--version` Show current Silo & Ansible version

```bash
$ ansible-silo --version
ansible-silo 2.2.0
ansible 2.4.2.0
ansible-lint 3.4.20
ansible installed on volume silo.some.user
```


### `--switch` Switch to any Ansible version

```bash
$ ansible-silo --switch v1.9.4-1
Switched to Ansible 1.9.4
```

The given version relates to any git tag or branch of the [Ansible github repository]. To switch to the development branch run:

```bash
$ ansible-silo --switch devel
Switched to Ansible 2.4.0
```

### `--reset` Resets a Silo volume

Will reset (delete) a Silo volume.

```bash
$ ansible-silo --reset
```

The volume can be specified by environment variable SILO_VOLUME:

```bash
$ SILO_VOLUME="foo" ansible-silo --reset
```


### `--shell` Log into container / execute command in container

You can log into the running Silo container by calling Silo with the `--shell` option. This can be used to install custom software in a Silo volume.

```bash
$ ansible-silo --shell
[ansible-silo 2.2.0|~/playbooks]$
```

All arguments after the `--shell` option will be directly executed.

```bash
$ ansible-silo --shell pip install pbr==3.1.1
/usr/lib/python2.7/site-packages/pip/commands/install.py:194: UserWarning: Disabling all use of wheels due to the use of --build-options / --global-options / --install-options.
  cmdoptions.check_install_build_global(options)
Collecting pbr==3.1.1
  Downloading pbr-3.1.1.tar.gz (102kB)
    100% |████████████████████████████████| 112kB 7.9MB/s
Installing collected packages: pbr
  Running setup.py install for pbr ... done
Successfully installed pbr
```


### Run Silo with different Ansible versions

You can run multiple Ansible versions in parallel by installing Ansible in different volumes. By default, Silo will use the volume `silo.<username>`, e.g. `silo.some.user`.

The name of the volume can be changed by passing the environment variable `SILO_VOLUME`. The volume name will be prepended with `silo.` and automatically be created if it does not exist. It will contain Ansible 2.4.2.0, the latest version as of writing this document. To change the Ansible version in that volume run the switch command:

```bash
$ SILO_VOLUME="1.9.6" ansible-silo --switch v1.9.6-1
Switched to Ansible 1.9.6

$ ansible-silo --version
ansible-silo 2.2.0
ansible 2.4.2.0
ansible-lint 3.4.20
ansible installed on volume silo.1.9.6

$ SILO_VOLUME="1.9.6" ansible-silo --version
ansible-silo 2.2.0
ansible 1.9.6
ansible-lint 3.4.20
ansible installed on volume silo.1.9.6
```


### Using Ansible

If you want to run playbooks or access any other resources like inventory files, make sure you're currently located in the directory of those files. You cannot access files outside of your current working directory since only this directory will be mounted in the Silo container.

If you [installed the Ansible scripts](#install-ansible-silo) you can use Ansible the exact same way you usually would. Just call `ansible`, `ansible-playbook`, etc.


#### Examples

Run a ping on all hosts

```bash
ansible all -m ping
# or
ansible-silo ansible all -m ping
```

Run a playbook

```bash
ansible-playbook some-playbook.yml -i some-inventory
# or
ansible-silo ansible-playbook some-playbook.yml -i some-inventory
```

Show man page for the template module:

```bash
ansible-doc template
or
ansible-silo ansible-doc template
```

Run ansible-lint on a playbook:

```bash
ansible-lint some-playbook.yml
# or
ansible-silo ansible-lint some-playbook.yml
```

### Disabling privileged mode

By default, Silo forwards the Docker socket into the container to be able to run Ansible against other containers. This requires the Silo container to run in [privileged mode]. To disable this you can define the environment variable `SILO_NO_PRIVILEGED`.


## Bundle mode

Silo can also be used as foundation to package and distribute your playbooks as Docker images. You can create a new bundle by calling:

```bash
ansible-silo --bundle foo
```

This will create all required files for building a custom Docker image based on Silo inside the newly created folder `foo`.

Store your playbooks, roles, inventory, `ansible.cfg` etc. inside `foo/playbooks` and then call the `build` script to create the Docker image.

The `foo` package also inherits most of Silos functionality. To install an executable for the bundle run:

```bash
docker run --interactive --tty --rm --volume "$HOME/bin:/silo_install_path" foo:latest --install
```

Now you can simply call `foo` to run your playbooks.

All files inside `foo` can be modified by you. For instance you **should** define a specific Ansible version in the Dockerfile. Have a look at the generated `README.md` inside your package for detailed description of the contained files.


## FAQ

### Why do I always have to enter my SSH key passphrase when Silo starts?

On OS X, forwarding of the SSH authentication socket [currently is not possible](https://github.com/groupon/ansible-silo/issues/2). Therefore Silo cannot use your ssh agent, even though it is forwarded to the container. If you have a password protected SSH key, you need to enter it once after the container is started. Since Silo is not persistent you have to enter it on every Silo run.


## Troubleshooting

If anything goes wrong, try to reset your Silo volume.

```bash
ansible-silo --reset
```

You can see the actual generated and executed `docker run` commands and all defined `SILO_*` environment vars by enabling [debug mode](#silo_debug).


## Versioning

Ansible Silo uses [SemVer]. Since Ansible Silo is the promise of a stable environment, we consider the smallest update of any contained dependency to be a potential breaking change and indicate such change by incrementing the major version number.

## Version history

### v2.2.0 (Jun 8, 2018)

* Adds support for non-tty environments.
* Adds `ansible-inventory` command.
* Adds support for ssh socket forwarded via [uber/ssh-agent-forward](https://hub.docker.com/r/uber/ssh-agent-forward/) (pinata).

### v2.1.1 (Jan 15, 2018)

* Fixes name of example function in bundle extension.

### v2.1.0 (Jan 9, 2018)

* Adds support for bundle extensions.


### v2.0.4 (Jan 8, 2018)

* Updates default Ansible version to 2.4.2.0.
* Consequently updates `ansible-lint` to 3.4.20 as 3.4.13 is incompatible.
* Moves ansible-lint into userspace, so the version in future can/must be managed by the user through `pip`.
* Adds new `ansible-config` command.
* Adds support for environment variable `ANSIBLE_VAULT_PASSWORD_FILE`.


### v2.0.3 (Sep 20, 2017)

* Adds Python module [ncclient](https://pypi.python.org/pypi/ncclient/0.5.3) 0.5.3
* Updates default Ansible version to 2.4.0.0.


### v2.0.2 (Sep 8, 2017)

* Switches git cloning of Ansible repository from git: protocol to https:


### v2.0.1 (Sep 6, 2017)

* Adds [jmespath](https://pypi.python.org/pypi/jmespath) and therefore fixes support for [JSON Query Filter](http://docs.ansible.com/ansible/latest/playbooks_filters.html#json-query-filter)


### v2.0.0 (Aug 31, 2017)

* Updates Alpine Linux from 3.4 to 3.6 - as well uses latest apk’s.
* Adds support for pip module installation.
* Introduces _userspace_ in volumes. Now custom software can be installed beside Ansible.
* Loads `.ansible-silo` (or `.bundle-name`) file from current working directory.
* Adds Docker support (Docker in Docker / DinD) - now can manage Docker containers and run Ansible against containers.
* Silo container by default now is started in privileged mode.
* Adds `sshpass` to support Ansible authentication via password.
* Introduces new `--reset` option. Can be used instead of `docker volume rm`.
* Improves output in installation routine - now shows image name and version from which software is installed.
* Updates default Ansible version to 2.3.2.0.
* Changes runner script file name - now is based on image-name and -version. This permits to skip runner script creation if it already exists, therefore improves container start time.
* Prevents forwarding of Silo exit codes as env vars into the container.
* Prevents forwarding of `GIT_*` env vars into the container to prevent potential git conflicts.
* Debug output now lists all `SILO_*` env vars.
* Fixes exit code declaration.
* Fixes order in `PYTHONPATH`.
* Removes `ansible-lint` from bundle `--version` output.
* Adds `pyyaml`.


### v1.3.3 (July 20, 2017)

* Converts starter scripts to symlinks
* Fixes help message command name


### v1.3.2 (July 17, 2017)

* Fixes version number in automated Docker build


### v1.3.1 (July 13, 2017)


* Initial public release

## Development

### Build pipeline

The `ansible-silo` image is an automated Docker build [triggered by Travis CI](https://github.com/groupon/ansible-silo/blob/master/.travis.yml#L31-L36), whenever a tag passed all tests. This means, to release a new version only a new tag in the form `v1.2.3` needs to be released.

There are custom build hooks in [`./hooks`](https://github.com/groupon/ansible-silo/blob/master/hooks) which will be triggered by the automated Docker build process.

The `ansible-silo-base` image needs to be built and uploaded manually. You can do this by running a command like:

```bash
make ansible-silo-base push-base
```

The version of the base image is hardcoded in the Makefile. Update accordingly if you plan to release a new base image.

For testing purpose you can also manually build the `ansible-silo` image by running a command like:

```bash
make ansible-silo
```

### Testing

Functional tests are implemented through [bats]. (0.4.0) After installing `bats` call:

```bash
make test-function
```

Be aware, tests modify the Ansible version of your default ansible-silo volume!

Code style tests are implemented via [shellcheck] (0.3.5). After installing `shellcheck` call:

```bash
make test-style
```

We also validate URLs inside all files for positive results via [awesome_bot] (1.17.1). After installing `awesome_bot` call:

```bash
make test-links
```

To run all tests call:

```bash
make test
```


### Base image

The APK package repository of Alpine only holds the very latest version of a package. This makes it currently impossible to install exact package versions and building of the image would fail once a new version of a package was released.

To ensure we are never forced to update any dependency when we build the silo Docker image, all APK dependencies are stored in the Docker image [ansible-silo-base]. If required, this image can be built and uploaded with the command `make ansible-silo-base push-base`. Make sure to afterwards update the tag in the [`Dockerfile`] and release a new version of ansible-silo.

## License

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


  [Alpine Linux]: https://hub.docker.com/_/alpine/
  [Ansible github repository]: https://github.com/ansible/ansible
  [ansible-silo-base]: https://github.com/groupon/ansible-silo/blob/master/base.Dockerfile
  [`Dockerfile`]: https://github.com/groupon/ansible-silo/blob/master/Dockerfile
  [ansible-lint]: https://github.com/willthames/ansible-lint
  [bats]: https://github.com/sstephenson/bats
  [shellcheck]: https://github.com/koalaman/shellcheck
  [awesome_bot]: https://github.com/dkhamsing/awesome_bot
  [privileged mode]: https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
  [SemVer]: http://semver.org/
