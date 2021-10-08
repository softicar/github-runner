# SoftiCAR GitHub Runner

A [GitHub Actions Runner](https://github.com/actions/runner) that builds a SoftiCAR Java project in an ephemeral Docker container.

## Main Features

- Unprivileged DinD (Docker-in-Docker) via [nestybox/sysbox](https://github.com/nestybox/sysbox).
  - Required for Selenium based unit tests.
- **TODO** mention dependency and image caching here, as soon as it's implemented
- **TODO** mention time-based runner auto-kill here, as soon as it's implemented
- **TODO** mention auto-update here, as soon as it's implemented

## Motivation

- Pull Requests may contain malicious code (either intentionally or by accident) that is executed during a Gradle build.
- On the Runner machine, that code is executed with the permissions of the user that runs the build.
- This way, files on the Runner machine can be manipulated, and/or its network access can be exploited.
- This enables DOS and other kinds of attacks against the Runner machine itself, and/or network-connected machines, unless counter-measures are applied.
- The Runner implementation in this repository aims to sandbox the build execution: It accepts the fact that the Runner machine may get compromised – but it limits the consequences.
- It does so by...
  1. starting an ephemeral [https://github.com/actions/runner](GitHub Actions Runner) in an unprivileged Docker container, and
  1. disposing the container after each build.
- The Runner implementation in this repository **does not** provide network isolation of builds.
  - This needs to be solved on the network level (see [Requirements](#Requirements)).

## Requirements

The following things must be installed or set up, in order to use the Runner implementation in this repository.

- [Docker](https://docs.docker.com/engine/install/ubuntu/)
  - The `softicar` user must be able to run `docker` commands (e.g. `docker ps`).
- [Sysbox](https://github.com/nestybox/sysbox/releases)
  - The `.deb` package that matches your distro must be installed.
- Admin access to the repository to build.
- Access to the Prevent-DEV GitHub bot user account, to create a [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token), with scopes (i.e. permissions) as described below.
- Permissions to create a new VM.

## Usage

1. In `Settings` / `Manage Access` of the repository to build, add the Prevent-DEV GitHub bot user as an `Admin`.
1. Log in to the account of the bot user.
   - Create a Personal Access Token, with the scopes (permissions) described in `softicar-github-runner.env-example`.
1. Create a VM from a recent Ubuntu template, and perform basic setup as usual.
1. Configure the firewall to isolate the VM from the rest of the network (e.g. via dedicated DMZ).
   - Allow outgoing traffic to the internet, via HTTP, HTTPS and SSH.
1. Log in as `softicar` user.
   - Delete the default RSA key pair from `/home/softicar/.ssh/` **and** `/root/.ssh/`
   - Run `ssh-keygen` to generate a new key pair for the `softicar` user.
   - Add the generated public key in the settings of the bot user account.
1. Install `gh`, and log in with the Personal Access Token of the bot user.
1. Clone this repository.
1. Copy `softicar-github-runner.env-example` to `/home/softicar/.softicar/softicar-github-runner.env`
   - Read the comments in that file, and define the environment variables.
1. Create `/home/softicar/.softicar/build.properties`
   - In that file, set `com.softicar.ivy.repository.url` to point to an Ivy repository that provides the [SoftiCAR Gradle Plugins](https://github.com/Prevent-DEV/com.softicar.gradle.plugins).
1. (Re-)Build the `softicar/softicar-github-runner` Docker image with `./rebuild-image.sh`
1. Create, enable and start the Systemd service:

       sudo install -m 644 softicar-github-runner.service /etc/systemd/system/
       sudo systemctl daemon-reload
       sudo systemctl enable --now softicar-github-runner

   - **TODO** create a simple installer script for the service, and update these instructions
1. Under `Settings` / `Actions` / `Runners` of your GitHub project, make sure that the runner is listed as `Idle`.
  - `systemctl status softicar-github-runner` should not contain errors
  - `docker logs runner` should not contain errors

## Related Projects

- Kudos to [PasseiDireto/gh-runner](https://github.com/PasseiDireto/gh-runner) which served as a base for this project.
- Further inspiration was drawn from [myoung34/docker-github-actions-runner](https://github.com/myoung34/docker-github-actions-runner).
- [Sysbox](https://github.com/nestybox/sysbox) enables the whole Docker-in-unprivileged-Docker approach.
