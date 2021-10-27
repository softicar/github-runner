# SoftiCAR GitHub Runner

A [GitHub Actions Runner](https://github.com/actions/runner) to build a SoftiCAR Java project in an ephemeral Docker container.

## 1 Main Features

- Ephemeral [GitHub Actions Runner](https://github.com/actions/runner) in a Docker container which is discarded after each build.
- Unprivileged Docker-in-Docker nesting, aka. _DinD_ (via [Sysbox](https://github.com/nestybox/sysbox); enables [Selenium](https://github.com/SeleniumHQ/selenium) based unit tests in nested Docker containers).
- An integrated cache proxy for build-time resources (via [Sonatype Nexus](https://github.com/sonatype/nexus-public); caches Docker images, Gradle plugins and Gradle dependencies).
- A systemd service to control the life cycle of the runner and cache proxy containers.
- Automatic upgrades to the most recent [GitHub Actions Runner release](https://github.com/actions/runner/releases).

## 2 Prerequisites

The following things are required to set up a SoftiCAR GitHub Runner:

1. Login credentials for the GitHub organization's build-bot user.
   - To create a [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).
1. Admin access to the repository to build.
   - To add the build-bot user as a member.
1. A DMZ-capable firewall, and permissions to edit its configuration.
   - To set up network isolation.
1. A dedicated Ubuntu 20.04 Server VM.
   - Specs:
     - 20 GB HDD
     - Recommended: 24 CPU threads, 24 GB RAM
     - Minimum: 8 CPU threads, 8 GB RAM
   - Unattended upgrades enabled, for security patches.

## 3 Setup

1. Configure your firewall to isolate the VM from the rest of the network (e.g. via dedicated DMZ). Allow _only:_
   - _Outgoing_ HTTP, HTTPS and SSH connections to the internet.
   - _Incoming_ HTTP and SSH connections from the internal network, for maintenance purposes.
   - Deny all other connections.
1. Log in to the GitHub UI with your personal account:
   - At `Settings` / `Manage Access` of the repository to build, add the build-bot user as an `Admin`.
1. Log in to the GitHub UI with the build-bot account:
   - Head to `(Build-Bot User Profile)` / `Settings` / `Developer settings` / `Personal access tokens`.
   - Create a Personal Access Token (PAT), with scopes as described in `softicar-github-runner.env-example`
   - Copy the PAT to a text editor -- you will need it below -- but don't save it.
1. Log in to the VM, as a non-root user.
   - If the user has an RSA key pair which is also used on another machine, **delete it**.
     - Do _not_ reuse an existing key pair for this machine.
     - Delete `id_rsa` and `id_rsa.pub` from `/home/<user>/.ssh/`
     - If existing, delete `id_rsa` and `id_rsa.pub` from `/root/.ssh/` as well.
   - Run `ssh-keygen` to generate a new key pair in `/home/<user>/.ssh/`
   - In the GitHub UI, at `(Build-Bot User Profile)` / `Settings` / `SSH and GPG keys`, add the content of the generated `id_rsa.pub` file.
1. Install `git`:

       sudo apt install git

1. Clone this repository:

       cd ~
       git clone https://github.com/Prevent-DEV/com.softicar.github.runner.git
       cd ~/com.softicar.github.runner

1. Run the setup script, and install all components (i.e. Docker, Docker-Compose, GitHub CLI, and Sysbox):

       ./setup install

   - Reboot the VM afterwards.
1. Log in to GitHub, using the PAT of the build-bot user:

       gh auth login

1. Copy `softicar-github-runner.env-example` to `/home/<user>/.softicar/softicar-github-runner.env`
   - Read the comments in that file, and define the environment variables accordingly.
1. Install and start the systemd service:

       ./service.sh install
       ./service.sh start

   - Note that `install` will also _enable_ the service, i.e. set it to auto-start after reboots.
1. Configure the cache proxy container:
   1. **TODO** describe nexus setup and repository configuration
1. In the GitHub UI, under `Settings` / `Actions` / `Runners` of the project to build, make sure that the runner is listed as `Idle`.
1. Make sure that no errors are reported in the outputs of:

       ./service.sh status
       ./service.sh logs

## 4 Limitations

- Each SoftiCAR GitHub Runner VM is configured to build _one_ specific repository.
  - It is _not_ yet possible to configure it as an organization-wide runner, in order to use it for several repositories.
  - This might change in the future.
- This runner implementation is heavily geared towards building SoftiCAR Java projects.
  - It probably won't be useful for other kinds of projects, beyond serving as technical showcase.

## 5 Motivation and Goals

### 5.1 Sandboxing

- Pull Requests may contain malicious code that is executed during the Gradle based build of a Java project. This can happen as part of an attack, or by accident.
- On the runner machine, that malicious code is executed with the permissions of the user that runs the build.
- This way, files on the runner machine can be manipulated, and/or available network access can be exploited.
- This enables DOS-, injection-, cache-poisoning- and other kinds of attacks against the runner machine and/or connected machines, unless counter-measures are applied.
- SoftiCAR GitHub Runner therefore sandboxes the build execution. It accepts the fact that the runner machine may get compromised – but it limits the consequences by:
  1. Creating and registering an ephemeral runner in an unprivileged Docker container,
  1. Executing the build on the containerized runner, and
  1. Unregistering and disposing the containerized runner after the build.
- Yet, SoftiCAR GitHub Runner by itself **does not** provide network isolation of builds. This needs to be solved on network infrastructure level.

### 5.2 Efficiency

As a result of the sandboxing approach, the runner containers are disposed after each build, and so are their internal caches.

This would result in Docker images, Gradle plugins and Gradle dependencies being downloaded from the internet for every single build, which would be wasteful in terms of bandwidth and time consumption. To avoid those repeated downloads, said build-time dependencies need to be cached outside the Docker container of the SoftiCAR GitHub Runner.

SoftiCAR GitHub Runner therefore employs [Sonatype Nexus](https://github.com/sonatype/nexus-public) as a persistent pull-through cache proxy, in a separate Docker container.

## 6 Contributing

Please read the [contribution guidelines](CONTRIBUTING.md) for this repository and keep our [code of conduct](CODE_OF_CONDUCT.md) in mind.

## 7 Related Projects

- [Docker](https://www.docker.com/)
- [Docker-Compose](https://github.com/docker/compose/releases)
- The official [GitHub Actions Runner](https://github.com/actions/runner).
- Kudos to [PasseiDireto/gh-runner](https://github.com/PasseiDireto/gh-runner) which served as a base for the runner container part of this project.
- Further inspiration was drawn from [myoung34/docker-github-actions-runner](https://github.com/myoung34/docker-github-actions-runner).
- [Sysbox](https://github.com/nestybox/sysbox) enables the _unprivileged Docker-in-Docker_ approach.
