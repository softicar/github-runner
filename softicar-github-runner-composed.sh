#!/bin/bash

SCRIPT_PATH=$(cd `dirname $0` && pwd)

# Unregisters the previously registered runner.
teardown() {
  echo "Shutting down containers..."
  docker-compose -f $SCRIPT_PATH/docker-compose.yml down --timeout 120
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
[[ ! $(which docker) ]] && { echo "Fatal: Docker is not installed."; exit 1; }
docker ps > /dev/null 2>&1 || { echo "Fatal: User ${USER} has insufficient permissions for docker commands."; exit 1; }
[[ ! $(which docker-compose) ]] && { echo "Fatal: Docker-Compose is not installed."; exit 1; }
[[ ! $(which sysbox-runc) ]] && { echo "Fatal: The 'sysbox' Docker runc is not installed."; exit 1; }

trap_signals

# docker-compose -f $SCRIPT_PATH/docker-compose.yml up -d nexus && \
# docker-compose -f $SCRIPT_PATH/docker-compose.yml up --build --force-recreate runner



docker-compose rm -f runner
docker-compose -f $SCRIPT_PATH/docker-compose.yml up -d nexus && \
docker-compose -f $SCRIPT_PATH/docker-compose.yml up --build runner






# TODO if the above does not cut it, try this:
# docker-compose rm -sv runner && \
# docker-compose up --no-deps -d nexus && \
# docker-compose up --no-deps --build runner
