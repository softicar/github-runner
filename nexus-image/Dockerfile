# Dockerfile for a sonatype/nexus3 based image with SoftiCAR specific configuration.

ARG NEXUS_VERSION
FROM sonatype/nexus3:${NEXUS_VERSION}

USER root

# Copy configuration scripts
ARG CONFIG_DIR=/nexus-data/softicar
RUN mkdir -p ${CONFIG_DIR}
COPY docker-hub.repository.json ${CONFIG_DIR}/
COPY gradle-plugins.repository.json ${CONFIG_DIR}/
COPY maven-central.repository.json ${CONFIG_DIR}/

# Copy the startup and configuration scripts
COPY startup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/startup.sh
COPY configure.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/configure.sh

USER nexus
CMD ["startup.sh"]
