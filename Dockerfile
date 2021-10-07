# A GitHub Actions Runner that builds SoftiCAR Java projects in a Docker container.
# Supports unprivileged DinD (Docker-in-Docker) via nestybox/sysbox.

# Use the Ubuntu base image provided by the "sysbox" vendor, "nestybox"
# see https://github.com/nestybox/dockerfiles/blob/master/ubuntu-focal-systemd-docker/Dockerfile
FROM nestybox/ubuntu-focal-systemd-docker

# Define versions
ARG ADOPT_OPEN_JDK_VERSION_DIR=15.0.2+7
ARG ADOPT_OPEN_JDK_VERSION_FILE=15.0.2_7
ARG DOCKER_COMPOSE_VERSION=1.27.4
ARG DUMB_INIT_VERSION=1.2.2
ARG GITHUB_RUNNER_VERSION=2.283.3

# Add "softicar" user, and add them to required groups.
# Remove default admin user (as defined in https://github.com/nestybox/dockerfiles/blob/master/ubuntu-focal-systemd/Dockerfile)
RUN useradd -m softicar \
    && usermod -aG sudo softicar \
    && usermod -aG docker softicar \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && userdel -r admin

# Install JDK
# see https://github.com/AdoptOpenJDK
WORKDIR /opt
RUN curl -Ls -o jdk.tar.gz https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk-${ADOPT_OPEN_JDK_VERSION_DIR}/OpenJDK15U-jdk_x64_linux_hotspot_${ADOPT_OPEN_JDK_VERSION_FILE}.tar.gz \
    && tar xzf ./jdk.tar.gz \
    && ln -s jdk-${ADOPT_OPEN_JDK_VERSION_DIR} jdk \
    && rm ./jdk.tar.gz
ENV PATH="/opt/jdk/bin:${PATH}"

# Install Java test-runtime dependencies:
#   git -- to clone repos
#   jq -- required by the script invoked with CMD
#   libfontconfig1 -- required during Java test runtime
# Afterwards, clear the apt package lists (see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/).
RUN apt-get update \
    && apt-get install -y \
       git \
       jq \
       libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# Install docker-compose
# see https://github.com/docker/compose/
RUN curl -Ls -o /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 \
    && chmod +x /usr/local/bin/docker-compose

# Install GitHub Actions Runner
# see https://github.com/actions/runner
WORKDIR /runner
RUN curl -Ls -o runner.tar.gz https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm ./runner.tar.gz \
    && ./bin/installdependencies.sh \
    && rm -rf /var/lib/apt/lists/*

# Install dumb-init, for subsequent use as entrypoint
# see https://github.com/Yelp/dumb-init
RUN curl -Ls -o /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 \
    && chmod +x /usr/local/bin/dumb-init

# Get stuff going
COPY lifecycle.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/lifecycle.sh
USER softicar
ENTRYPOINT ["/usr/local/bin/dumb-init", "-v", "--"]
CMD ["lifecycle.sh"]
