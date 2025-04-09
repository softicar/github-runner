# Defines common environment variables and functions for the scripts in this folder.
#
# Sourced by other scripts.

SCRIPT_SUPPORTED_RELEASES=noble
SCRIPT_WORKING_DIRECTORY=$(cd `dirname $0` && pwd)

DOCKER_COMPOSE_VERSION=1.29.2
DOCKER_COMPOSE_DESTINATION=/usr/bin/docker-compose
DOCKER_COMPOSE_HOME=/opt/docker-compose
DOCKER_COMPOSE_FILE=$DOCKER_COMPOSE_HOME/docker-compose-Linux-x86_64-$DOCKER_COMPOSE_VERSION

SERVICE_FILE=softicar-github-runner.service
SERVICE_FILE_DESTINATION=/etc/systemd/system/$SERVICE_FILE
SERVICE_SCRIPT_ENVIRONMENT_FILE=softicar-github-runner-service.env
SERVICE_SCRIPT_PATH=$SCRIPT_WORKING_DIRECTORY/systemd-service/softicar-github-runner-service.sh
SERVICE_TEMPLATE_PATH=systemd-service/softicar-github-runner.service-template

SYSBOX_VERSION=0.5.2

REPOSITORY_NAME_EXAMPLE="<owner>/<repository>"
REPOSITORY_NAME_REGEX="[a-zA-Z0-9]([_.-]?[a-zA-Z0-9]+)*/[a-zA-Z0-9]([_.-]?[a-zA-Z0-9]+)*"

RUNNER_LABELS_DEFAULT="ephemeral,dind"
RUNNER_NAME_DEFAULT="softicar-github-runner"
RUNNER_NAME_REGEX="[a-zA-Z0-9]([_.-]?[a-zA-Z0-9]+)*"

function is_docker_installed() {
  if [[ $(which docker) ]]; then true; else false; fi
}

function assert_docker_installed() {
  ! is_docker_installed && { echo "Docker is not installed. Install it with: ./setup.sh"; exit 1; }
}

function is_docker_compose_installed() {
  if [[ -f $DOCKER_COMPOSE_DESTINATION ]]; then true; else false; fi
}

function assert_docker_compose_installed() {
  ! is_docker_compose_installed && { echo "Docker-Compose is not installed. Install it with: ./setup.sh"; exit 1; }
}

function is_service_installed() {
  if [[ -f $SERVICE_FILE_DESTINATION ]]; then true; else false; fi
}

function assert_service_installed() {
  ! is_service_installed && { echo "Service is not installed. Install it with: ./setup.sh"; exit 1; }
}

function is_sysbox_installed() {
  if [[ $(which sysbox-runc) ]]; then true; else false; fi
}

function assert_sysbox_installed() {
  ! is_sysbox_installed && { echo "Sysbox is not installed. Install it with: ./setup.sh"; exit 1; }
}

function print_release_warning_if_necessary {
  local system_release=$(lsb_release -cs)
  if [[ ! $SCRIPT_SUPPORTED_RELEASES == *"$system_release"* ]]; then
    echo ""
    echo "WARNING:"
    echo "The following Ubuntu releases are supported: $SCRIPT_SUPPORTED_RELEASES"
    echo "This system is based upon: $system_release"
    echo "The setup script is not guaranteed to work properly on this system."
  fi
}
