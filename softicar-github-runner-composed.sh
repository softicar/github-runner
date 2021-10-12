#!/bin/bash

DOCKER_COMPOSE_ENV_FILE="/home/${USER}/.softicar/softicar-github-runner-composed.env"
SCRIPT_PATH=$(cd `dirname $0` && pwd)

# Unregisters the previously registered runner.
teardown() {
  echo "Shutting down containers..."
  docker-compose down
  echo "Containers were shut down."
}

# Traps various signals that could terminate this script, to perform cleanup operations.
# Exits with 128+n for any trapped signal with an ID of n (cf. `kill -l`).
trap_signals() {
  trap 'teardown; exit 130;' SIGINT
  trap 'teardown; exit 143;' SIGTERM
}

# -------- Main Script -------- #

# Check prerequisites
[[ ! -f $DOCKER_COMPOSE_ENV_FILE ]] && { echo "Fatal: $DOCKER_COMPOSE_ENV_FILE not found."; exit 1; }
[[ ! $(which docker) ]] && { echo "Fatal: Docker is not installed."; exit 1; }
docker ps > /dev/null 2>&1 || { echo "Fatal: User ${USER} has insufficient permissions for docker commands."; exit 1; }
[[ ! $(which docker-compose) ]] && { echo "Fatal: Docker-Compose is not installed."; exit 1; }
[[ ! $(which sysbox-runc) ]] && { echo "Fatal: The 'sysbox' Docker runc is not installed."; exit 1; }

trap_signals

docker-compose up -f $SCRIPT_PATH/docker-compose.yml --env-file $DOCKER_COMPOSE_ENV_FILE --no-deps -d nexus && \
docker-compose up -f $SCRIPT_PATH/docker-compose.yml --env-file $DOCKER_COMPOSE_ENV_FILE --no-deps --build --force-recreate runner







# TODO if the above does not cut it, try this:
# docker-compose rm --env-file $DOCKER_COMPOSE_ENV_FILE -sv runner && \
# docker-compose up --env-file $DOCKER_COMPOSE_ENV_FILE --no-deps -d nexus && \
# docker-compose up --env-file $DOCKER_COMPOSE_ENV_FILE --no-deps --build runner
