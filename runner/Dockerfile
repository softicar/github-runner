# Dockerfile for the docker-in-docker-enabled SoftiCAR spin of GitHub Actions Runner.

# Use the Ubuntu base image provided by the "sysbox" vendor, "nestybox"
# see https://github.com/nestybox/dockerfiles/blob/master/ubuntu-focal-systemd-docker/Dockerfile
FROM nestybox/ubuntu-focal-systemd-docker

# Add "softicar" user, and add them to required groups.
# Remove default admin user (as defined in https://github.com/nestybox/dockerfiles/blob/master/ubuntu-focal-systemd/Dockerfile)
RUN useradd -m softicar \
    && usermod -aG sudo softicar \
    && usermod -aG docker softicar \
    && echo "%sudo   ALL= NOPASSWD: /usr/sbin/service docker start" > /etc/sudoers \
    && userdel -r admin

# Install JDK
# see https://github.com/AdoptOpenJDK
ARG RUNNER_ADOPT_OPEN_JDK_VERSION
WORKDIR /opt
RUN RUNNER_ADOPT_OPEN_JDK_VERSION_FILE=$(echo $RUNNER_ADOPT_OPEN_JDK_VERSION | sed 's/+/_/') \
    && curl -Ls -o jdk.tar.gz https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk-${RUNNER_ADOPT_OPEN_JDK_VERSION}/OpenJDK15U-jdk_x64_linux_hotspot_${RUNNER_ADOPT_OPEN_JDK_VERSION_FILE}.tar.gz \
    && tar xzf ./jdk.tar.gz \
    && ln -s jdk-${RUNNER_ADOPT_OPEN_JDK_VERSION} jdk \
    && rm ./jdk.tar.gz
ENV PATH="/opt/jdk/bin:${PATH}"

# Install Java test-runtime dependencies:
#   git -- to clone repos
#   libfontconfig1 -- required during Java test runtime
# Afterwards, clear the apt package lists (see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/).
RUN apt-get update \
    && apt-get install -y \
       git \
       libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# Install docker-compose
# see https://github.com/docker/compose/
ARG RUNNER_DOCKER_COMPOSE_VERSION
RUN curl -Ls -o /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/${RUNNER_DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 \
    && chmod +x /usr/local/bin/docker-compose

# Install dumb-init, for subsequent use as entrypoint
# see https://github.com/Yelp/dumb-init
ARG RUNNER_DUMB_INIT_VERSION
RUN curl -Ls -o /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${RUNNER_DUMB_INIT_VERSION}/dumb-init_${RUNNER_DUMB_INIT_VERSION}_x86_64 \
    && chmod +x /usr/local/bin/dumb-init

# Install GitHub Actions Runner
# see https://github.com/actions/runner
ARG RUNNER_VERSION_OVERRIDE
WORKDIR /runner
RUN curl -Ls -o runner.tar.gz $( \
      [ $RUNNER_VERSION_OVERRIDE ] \
      && echo "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION_OVERRIDE}/actions-runner-linux-x64-${RUNNER_VERSION_OVERRIDE}.tar.gz" \
      || echo $(curl -Ls https://api.github.com/repos/actions/runner/releases/latest | grep -oP '(?<="browser_download_url": ")[^"]*' | grep linux-x64) \
    ) \
    && tar xzf ./runner.tar.gz \
    && rm ./runner.tar.gz \
    && ./bin/installdependencies.sh \
    && rm -rf /var/lib/apt/lists/*

# Create Docker daemon configuration
ARG RUNNER_DOCKER_DAEMON_CONFIG='{ "insecure-registries" : ["nexus:8123"], "registry-mirrors": ["http://nexus:8123/"] }'
RUN mkdir -p /etc/docker/ && echo "$RUNNER_DOCKER_DAEMON_CONFIG" > /etc/docker/daemon.json

# Copy the startup script
COPY startup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/startup.sh

# Get stuff going
USER softicar
ENTRYPOINT ["/usr/local/bin/dumb-init", "-v", "--"]
CMD ["startup.sh"]
