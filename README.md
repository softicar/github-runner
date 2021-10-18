# SoftiCAR GitHub Runner

A [GitHub Actions Runner](https://github.com/actions/runner) that builds a SoftiCAR Java project in an ephemeral Docker container.

## 1 Main Features

- Ephemeral [GitHub Actions Runner](https://github.com/actions/runner) in a Docker container which is discarded after each build.
- Unprivileged Docker-in-Docker nesting, aka. _DinD_, via [nestybox/sysbox](https://github.com/nestybox/sysbox) (required for Selenium based unit tests).
- A systemd service to control the life cycle of the containerized Runner.
- **TODO** mention dependency and image caching here, as soon as it's implemented
- **TODO** mention auto-update here, as soon as it's implemented
- **TODO** mention time-based runner auto-kill here, as soon as it's implemented

## 2 Prerequisites

The following things are required to set up a SoftiCAR GitHub Runner:

1. Login credentials for the Prevent-DEV GitHub bot user.
   - To create a [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).
1. Admin access to the repository to build.
   - To add the Prevent-DEV GitHub bot user as a member.
1. Permissions to edit the firewall configuration.
   - To set up network isolation.
1. A new VM, cloned from the SoftiCAR Ubuntu 20.04 Server template.
   - [GitHub CLI](https://github.com/cli/cli) (i.e. the `gh` command) must be installed, and the Prevent-DEV GitHub bot user must be logged in, to clone this repository.

## 3 Setup

1. Configure the firewall to isolate the VM from the rest of the network (e.g. via dedicated DMZ).
   - Allow _outgoing_ HTTP, HTTPS and SSH connections to the internet.
   - Allow _incoming_ SSH connections from the internal network only, for maintenance purposes.
1. In `Settings` / `Manage Access` of the repository to build, add the Prevent-DEV GitHub bot user as an `Admin`.
1. Log in to the bot user account, and create a Personal Access Token (PAT).
   - Enable scopes (permissions) as described in `softicar-github-runner.env-example`
   - Copy it to a text editor but don't save it.
1. Log in to the VM, as `softicar` user.
   - Delete the default RSA key pairs from both `/home/softicar/.ssh/` **and** `/root/.ssh/`
   - Run `ssh-keygen` to generate a new key pair in `/home/softicar/.ssh/`
   - Add the generated _public_ key in the settings of the bot user account.
1. Run `gh auth login` to log in to GitHub, using the generated PAT of the bot user.
1. Clone this repository:

       cd ~
       gh repo clone https://github.com/Prevent-DEV/com.softicar.github.runner.git
       cd com.softicar.github.runner

1. Run the setup script, and install all components:

       ./setup install

1. Copy `softicar-github-runner.env-example` to `/home/softicar/.softicar/softicar-github-runner.env`
   - Read the comments in that file, and define the environment variables accordingly.
1. Create `/home/softicar/.softicar/build.properties` -- in that file:
   - Set `com.softicar.ivy.repository.url` to point to an Ivy repository that provides the [SoftiCAR Gradle Plugins](https://github.com/Prevent-DEV/com.softicar.gradle.plugins).
   - **TODO** describe setting the `...maven.proxies` property as soon as caching is ready for prime time
1. **TODO** describe nexus repository configuration
1. Install and start the systemd service:

       ./service.sh install
       ./service.sh start

1. In the GitHub UI, under `Settings` / `Actions` / `Runners` of the project to build, make sure that the runner is listed as `Idle`.
1. Make sure that no errors are reported in the outputs of:

       ./service.sh status
       ./service.sh logs

## 4 Motivation and Goals

### 4.1 Sandboxing

- Pull Requests may contain malicious code that is executed during the Gradle based build of a Java project. This can happen as part of an attack, or by accident.
- On the [Runner](https://github.com/actions/runner) machine, that malicious code is executed with the permissions of the user that runs the build.
- This way, files on the Runner machine can be manipulated, and/or available network access can be exploited.
- This enables DOS-, injection-, and other kinds of attacks against the Runner machine and/or connected machines, unless counter-measures are applied.
- The SoftiCAR GitHub Runner implementation therefore sandboxes the build execution. It accepts the fact that the Runner machine may get compromised – but it limits the consequences by:
  1. Creating and registering an ephemeral Runner in an unprivileged Docker container,
  1. Executing the build on the containerized Runner, and
  1. Unregistering and disposing the containerized Runner after the build.
- Yet, the SoftiCAR GitHub Runner implementation **does not** provide network isolation of builds. This needs to be solved on network infrastructure level.

### 4.2 Efficiency

Because the Runner containers are ephemeral, ... **TODO** describe how we deal with constant cache wipes

## 5 Related Projects

- [Docker](https://docs.docker.com/engine/install/ubuntu/)
- [Docker-Compose](https://github.com/docker/compose/releases)
- The official [GitHub Actions Runner](https://github.com/actions/runner).
- Kudos to [PasseiDireto/gh-runner](https://github.com/PasseiDireto/gh-runner) which served as a base for the Runner container part of this project.
- Further inspiration was drawn from [myoung34/docker-github-actions-runner](https://github.com/myoung34/docker-github-actions-runner).
- [Sysbox](https://github.com/nestybox/sysbox) enables the whole Docker-in-unprivileged-Docker approach.
