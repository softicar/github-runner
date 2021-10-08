#!/bin/bash

# Main startup script of the SoftiCAR GitHub Runner.
# Should be invoked by a systemd service.

BUILD_PROPERTIES_FILE="/home/${USER}/.softicar/build.properties"
CONTAINER_ENV_FILE="/home/${USER}/.softicar/softicar-github-runner.env"
IMAGE_NAME="softicar/softicar-github-runner"

# Check prerequisites
[[ ! -f $BUILD_PROPERTIES_FILE ]] && { echo "Fatal: $BUILD_PROPERTIES_FILE not found."; exit 1; }
[[ ! -f $CONTAINER_ENV_FILE ]] && { echo "Fatal: $CONTAINER_ENV_FILE not found."; exit 1; }
[[ ! $(which docker) ]] && { echo "Fatal: Docker is not installed."; exit 1; }
docker ps > /dev/null 2>&1 || { echo "Fatal: User ${USER} has insufficient permissions for docker commands."; exit 1; }
[[ ! $(which sysbox-runc) ]] && { echo "Fatal: The 'sysbox' Docker runc is not installed."; exit 1; }

# Start the container
docker run \
  --name=runner \
  --rm \
  --runtime sysbox-runc \
  --env-file=$CONTAINER_ENV_FILE \
  --mount type=bind,readonly,src=$BUILD_PROPERTIES_FILE,dst=$BUILD_PROPERTIES_FILE \
  $IMAGE_NAME
