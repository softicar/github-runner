# Dockerfile for a sonatype/nexus3 based image with SoftiCAR specific configuration.

ARG NEXUS_VERSION
FROM sonatype/nexus3:${NEXUS_VERSION}

USER root

# Copy configuration scripts
ARG NEXUS_CONFIG_DIR=/nexus-data/softicar
RUN mkdir -p ${NEXUS_CONFIG_DIR}
COPY docker-hub.repository.json ${NEXUS_CONFIG_DIR}/
COPY gradle-plugins.repository.json ${NEXUS_CONFIG_DIR}/
COPY maven-central.repository.json ${NEXUS_CONFIG_DIR}/
COPY security-realms.json ${NEXUS_CONFIG_DIR}/

# Copy the startup and configuration scripts
COPY startup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/startup.sh
COPY configure.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/configure.sh

USER nexus
CMD ["startup.sh"]
