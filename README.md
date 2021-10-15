# SoftiCAR GitHub Runner

A [GitHub Actions Runner](https://github.com/actions/runner) that builds a SoftiCAR Java project in an ephemeral Docker container.

## Main Features

- Unprivileged DinD (Docker-in-Docker) via [nestybox/sysbox](https://github.com/nestybox/sysbox).
  - Required for Selenium based unit tests.
- **TODO** mention dependency and image caching here, as soon as it's implemented
- **TODO** mention auto-update here, as soon as it's implemented
- **TODO** mention time-based runner auto-kill here, as soon as it's implemented

## Motivation

- Pull Requests may contain malicious code that is executed during the Gradle based build of a Java project.
- On the Runner machine, that code is executed with the permissions of the user that runs the build.
- This way, files on the Runner machine can be manipulated, and/or the network access of the machine can be exploited.
- This enables DOS and other kinds of attacks against the Runner machine itself, and/or network-connected machines, unless counter-measures are applied.
- The Runner implementation in this repository aims to effectively sandbox the build execution. It accepts the fact that the Runner machine may get compromised – either intentionally or unintentionally – but it limits the consequences.
- It does so by...
  1. starting an ephemeral [https://github.com/actions/runner](GitHub Actions Runner) in an unprivileged Docker container, and
  1. disposing the container after each build.
- However, the Runner implementation in this repository **does not** provide network isolation of builds.
  - This needs to be solved on the network level (see [Requirements](#Requirements)).

## Requirements

The following things must be available or installed:

- A VM, cloned from the SoftiCAR Ubuntu Server template, with the following software installed:
  - [Docker](https://docs.docker.com/engine/install/ubuntu/) -- The `softicar` user must be able to run `docker` commands (e.g. `docker ps`).
  - [Docker-Compose](https://github.com/docker/compose/releases) -- version 1.x
  - [Sysbox](https://github.com/nestybox/sysbox/releases) -- The `.deb` package that matches your distro must be installed.
  - [GitHub CLI](https://github.com/cli/cli)
- Admin access to the repository to build, to add the Prevent-DEV GitHub bot user.
- Login credentials for the Prevent-DEV GitHub bot user account, to create a [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).
- Permissions to edit the firewall configuration.

## Usage

1. In `Settings` / `Manage Access` of the repository to build, add the Prevent-DEV GitHub bot user as an `Admin`.
1. Log in to the bot user account, and create a Personal Access Token (PAT).
   - Enable scopes (permissions) as described in `softicar-github-runner.env-example`.
1. Configure the firewall to isolate the VM from the rest of the network (e.g. via dedicated DMZ).
   - Allow outgoing connections to the internet, via HTTP, HTTPS and SSH.
   - Allow incoming connections from the internal network, via SSH, for maintenance purposes.
1. Log in to the VM, as `softicar` user.
   - Delete the default RSA key pair from `/home/softicar/.ssh/` **and** `/root/.ssh/`
   - Run `ssh-keygen` to generate a new key pair for the `softicar` user in `/home/softicar/.ssh/`.
   - Add the generated public key in the settings of the bot user account.
1. Run `gh auth login` to log in to GitHub, using the PAT of the bot user.
1. Clone this repository.
1. Copy `softicar-github-runner.env-example` to `/home/softicar/.softicar/softicar-github-runner.env`
   - Read the comments in that file, and define the environment variables.
1. Create `/home/softicar/.softicar/build.properties`. In that file:
   - Set `com.softicar.ivy.repository.url` to point to an Ivy repository that provides the [SoftiCAR Gradle Plugins](https://github.com/Prevent-DEV/com.softicar.gradle.plugins).
   - **TODO** describe setting the `...maven.proxies` property as soon as caching is ready for prime time
1. Install and start the systemd service:

       ./service.sh install
       ./service.sh start

1. Under `Settings` / `Actions` / `Runners` of the GitHub project, make sure that the runner is listed as `Idle`.
1. Make sure that no errors are reported in the outputs of:

       ./service.sh status
       ./service.sh logs

## Related Projects

- The official [GitHub Actions Runner](https://github.com/actions/runner).
- Kudos to [PasseiDireto/gh-runner](https://github.com/PasseiDireto/gh-runner) which served as a base for the Runner container part of this project.
- Further inspiration was drawn from [myoung34/docker-github-actions-runner](https://github.com/myoung34/docker-github-actions-runner).
- [Sysbox](https://github.com/nestybox/sysbox) enables the whole Docker-in-unprivileged-Docker approach.
