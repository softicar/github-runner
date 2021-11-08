#!/bin/bash

# Lifecycle control script for the Docker-Compose project of SoftiCAR GitHub Runner.
#
# Invoked by softicar-github-runner.service

COMPOSE_DOWN_TIMEOUT=30
COMPOSE_FILE_NAME=softicar-github-runner-service-docker-compose.yml
SCRIPT_PATH=$(cd `dirname $0` && pwd)

# Unregisters the previously registered runner.
teardown() {
  echo "Shutting down containers..."
  if docker-compose -f $SCRIPT_PATH/$COMPOSE_FILE_NAME down --timeout $COMPOSE_DOWN_TIMEOUT; then
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
  [[ ! $(which jq) ]] && { echo "FATAL: 'jq' is not installed."; exit 1; }
  [[ ! $(which curl) ]] && { echo "FATAL: 'curl' is not installed."; exit 1; }
}

# Generates a new runner token from a personal access token, and exports it.
generate_runner_token() {
  echo "Generating runner token..."
  [[ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]] && { echo "FATAL: GITHUB_PERSONAL_ACCESS_TOKEN must be defined." ; exit 1; }
  [[ -z "$GITHUB_REPOSITORY" ]] && { echo "FATAL: GITHUB_REPOSITORY must be defined." ; exit 1; }

  local auth_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token"
  local token_response=$(curl -sX POST -H "Authorization: token ${GITHUB_PERSONAL_ACCESS_TOKEN}" "${auth_url}")
  GITHUB_RUNNER_TOKEN=$(echo "${token_response}" | jq .token --raw-output)

  if [ "${GITHUB_RUNNER_TOKEN}" == "null" ]; then
    echo "FATAL: Failed to generate runner token: ${token_response}"
    exit 1
  else
    echo "Runner token generated."
    export GITHUB_RUNNER_TOKEN
  fi
}

# Removes unreferenced images that have both "repository=none" and "tag=none".
remove_dangling_images() {
  echo "Removing dangling images..."

  docker rmi $(docker images --filter "dangling=true" -q --no-trunc) && \
  echo "Dangling images removed."
}

# -------------------------------- Main Script -------------------------------- #

check_prerequisites

trap_signals

# If $RUNNER_ENV_FILE exists, source it and export all contained environment variables, to make them
# available to all child processes spawned by docker-compose.
# This is required to have those variables available when (re-)building the "runner" image.
[ -f $RUNNER_ENV_FILE ] && set -o allexport && source $RUNNER_ENV_FILE && set +o allexport

generate_runner_token

# Remove the old "runner" to get rid of its content.
docker-compose -f $SCRIPT_PATH/$COMPOSE_FILE_NAME rm -f runner

# Start "nexus" if not yet running,
# (re-)build and (re-)start "runner",
# and remove dangling images from previous builds.
docker-compose -f $SCRIPT_PATH/$COMPOSE_FILE_NAME up -d nexus && \
docker-compose -f $SCRIPT_PATH/$COMPOSE_FILE_NAME up --build runner && \
remove_dangling_images
