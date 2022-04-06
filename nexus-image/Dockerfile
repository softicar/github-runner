# Dockerfile for a sonatype/nexus3 based image with SoftiCAR specific configuration.

ARG NEXUS_VERSION
FROM sonatype/nexus3:${NEXUS_VERSION}

USER root

# Copy configuration files
ARG NEXUS_CONFIG_DIR=/nexus-data/softicar
RUN mkdir -p ${NEXUS_CONFIG_DIR}
COPY docker-hub.repository.json ${NEXUS_CONFIG_DIR}/
COPY gradle-plugins.repository.json ${NEXUS_CONFIG_DIR}/
COPY maven-central.repository.json ${NEXUS_CONFIG_DIR}/
COPY security-realms.json ${NEXUS_CONFIG_DIR}/

# Copy startup.sh and configure.sh
COPY startup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/startup.sh
COPY configure.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/configure.sh

# Configure Karaf subsystem properties
RUN sed -i 's/storage.diskCache.diskFreeSpaceLimit=.*/storage.diskCache.diskFreeSpaceLimit=512/g' /opt/sonatype/nexus/etc/karaf/system.properties

USER nexus
CMD ["startup.sh"]
