#!/bin/bash

# Lifecycle control script for the Docker-Compose project of SoftiCAR GitHub Runner.
#
# Invoked by softicar-github-runner.service

# Constants
COMPOSE_DOWN_TIMEOUT=30
SCRIPT_PATH=$(cd `dirname $0` && pwd)

# Unregisters the previously registered runner.
teardown() {
  echo "Shutting down containers..."
  if docker-compose -f $SCRIPT_PATH/docker-compose.yml down --timeout $COMPOSE_DOWN_TIMEOUT; then
    echo "Containers were shut down."
    exit 0
  else
    echo "FATAL: Failed to shut down containers."
    exit 1
  fi
}

# Traps various signals that could terminate this script, to perform cleanup operations.
trap_signals() {
  trap 'teardown;' SIGINT
  trap 'teardown;' SIGTERM
}

# Checks prerequisites that must be fulfilled before anything else is done.
check_prerequisites() {
  [[ ! $(which docker) ]] && { echo "FATAL: Docker is not installed."; exit 1; }
  docker ps > /dev/null 2>&1 || { echo "FATAL: User ${USER} has insufficient permissions for docker commands."; exit 1; }
  [[ ! $(which docker-compose) ]] && { echo "FATAL: Docker-Compose is not installed."; exit 1; }
  [[ ! $(which sysbox-runc) ]] && { echo "FATAL: The 'sysbox' Docker runc is not installed."; exit 1; }
}

# -------------------------------- Main Script -------------------------------- #

check_prerequisites

trap_signals

# If $RUNNER_ENV_FILE exists, source it and export all contained environment variables, to make them
# available to all child processes spawned by docker-compose.
# This is particularly important to have the variables available during re-builds of the "runner" image.
[ -f $RUNNER_ENV_FILE ] && set -o allexport && source $RUNNER_ENV_FILE && set +o allexport

# Remove the old "runner" before (re-)starting it, to reset its content.
docker-compose -f $SCRIPT_PATH/docker-compose.yml rm -f runner

# Make sure that "nexus" gets or remains started, and that "runner" gets
# (re-)built and (re-)started.
docker-compose -f $SCRIPT_PATH/docker-compose.yml up -d nexus && \
docker-compose -f $SCRIPT_PATH/docker-compose.yml up --build runner
