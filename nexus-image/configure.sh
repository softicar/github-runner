#!/bin/bash

# Configuration script for the "nexus" container.
#
# Invoked by startup.sh.

cd `dirname $0`

NEXUS_DATA_DIR=/nexus-data
NEXUS_DATA_SOFTICAR_DIR=$NEXUS_DATA_DIR/softicar

ADMIN_PASSWORD_DEFAULT_FILE="${NEXUS_DATA_DIR}/admin.password"
ADMIN_PASSWORD_NEW_FILE="${NEXUS_DATA_DIR}/admin.password.changed"

NEXUS_HOST="http://localhost:8081"
NEXUS_REST_BASE_URL="${NEXUS_HOST}/service/rest"
NEXUS_STARTUP_TIMEOUT_SECONDS=60

# -------- Functions -------- #

configure_nexus() {
  log "Starting configuration..."

  # Change admin password
  # Note: This also causes Nexus to automatically delete the default admin password file.
  local default_password=$(head -n1 $ADMIN_PASSWORD_DEFAULT_FILE)
  local new_password=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 16)
  curl -sf -u "admin:${default_password}" -X PUT -H "Content-Type: text/plain" -d "${new_password}" "${NEXUS_REST_BASE_URL}/v1/security/users/admin/change-password" -o /dev/null && \
  echo "${new_password}" > $ADMIN_PASSWORD_NEW_FILE && \
  log "Admin password changed. New password was written to: $ADMIN_PASSWORD_NEW_FILE"

  # Enable anonymous access
  curl -sf -u "admin:${new_password}" -X PUT -H "Content-Type: application/json" -d '{ "enabled": true }' "${NEXUS_REST_BASE_URL}/v1/security/anonymous" -o /dev/null && \
  log "Anonymous access enabled."

  # Create repo: docker-hub
  curl -sf -u "admin:${new_password}" -X POST -H "Content-Type: application/json" -d "@$NEXUS_DATA_SOFTICAR_DIR/docker-hub.repository.json" "${NEXUS_REST_BASE_URL}/v1/repositories/docker/proxy" -o /dev/null && \
  log "Added repository: docker-hub"

  # Create repo: gradle-plugins
  curl -sf -u "admin:${new_password}" -X POST -H "Content-Type: application/json" -d "@$NEXUS_DATA_SOFTICAR_DIR/gradle-plugins.repository.json" "${NEXUS_REST_BASE_URL}/v1/repositories/maven/proxy" -o /dev/null && \
  log "Added repository: gradle-plugins"

  # Create repo: maven-central
  curl -sf -u "admin:${new_password}" -X POST -H "Content-Type: application/json" -d "@$NEXUS_DATA_SOFTICAR_DIR/maven-central.repository.json" "${NEXUS_REST_BASE_URL}/v1/repositories/maven/proxy" -o /dev/null && \
  log "Added repository: maven-central"

  # Configure security realms
  curl -sf -u "admin:${new_password}" -X PUT -H "Content-Type: application/json" -d "@$NEXUS_DATA_SOFTICAR_DIR/security-realms.json" "${NEXUS_REST_BASE_URL}/v1/security/realms/active" -o /dev/null && \
  log "Configured security realms."

  log "Finished configuration."
}

log() {
  echo "Nexus Configuration Script: $1"
}

# -------- Main Script -------- #

TIME_MAX=$(($(date +%s) + NEXUS_STARTUP_TIMEOUT_SECONDS))
until curl -sf "${NEXUS_HOST}" -o /dev/null; do
  [ $(date +%s) -gt $TIME_MAX ] && { log "FATAL: Timeout after $NEXUS_STARTUP_TIMEOUT_SECONDSs while waiting for the web server."; exit 1; }
  log "Waiting for the web server..."
  sleep 1;
done
log "Web server is available."

if [ -f $ADMIN_PASSWORD_DEFAULT_FILE ]; then
  log "Found the default admin password file at: $ADMIN_PASSWORD_DEFAULT_FILE"
  log "Assuming that Nexus was not yet configured."
  configure_nexus
else
  log "Did not find the default admin password file at: $ADMIN_PASSWORD_DEFAULT_FILE"
  log "Assuming that Nexus was already configured."
fi

log "Bye."
