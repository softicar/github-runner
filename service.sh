#!/bin/bash

# SoftiCAR GitHub Runner - Systemd Service Management Script
#
# Facilitates installation, administration and uninstallation of the
# systemd service that manages the SoftiCAR GitHub Runner lifecycle.
#
# Run without parameters for a list of available commands.

SELF_PATH=$(cd `dirname $0` && pwd)
SERVICE_FILE=softicar-github-runner.service
SERVICE_FILE_DESTINATION=/etc/systemd/system/$SERVICE_FILE
SERVICE_TEMPLATE=softicar-github-runner.service-template
SERVICE_SCRIPT_PATH=$SELF_PATH/softicar-github-runner.sh
SERVICE_SCRIPT_ENVIRONMENT_FILE=softicar-github-runner.env
RUNNER_NAME_DEFAULT="softicar-github-runner"
RUNNER_NAME_REGEX="[a-zA-Z0-9]([_.-]?[a-zA-Z0-9]+)*"
RUNNER_LABELS_DEFAULT="ephemeral,dind"
REPOSITORY_NAME_EXAMPLE="SoftiCAR/some-repo"
REPOSITORY_NAME_REGEX="[a-zA-Z0-9]([_.-]?[a-zA-Z0-9]+)*/[a-zA-Z0-9]([_.-]?[a-zA-Z0-9]+)*"

function service_install {
  if [[ ! -f $SERVICE_FILE_DESTINATION ]]; then
    [[ -f $SERVICE_TEMPLATE ]] || { echo "FATAL: Could not find the service template at $SERVICE_TEMPLATE"; exit 1; }
    [[ -f $SERVICE_SCRIPT_PATH ]] || { echo "FATAL: Could not find the service script at $SERVICE_SCRIPT_PATH"; exit 1; }

    echo "Installing service..."

    prompt_for_service_user SERVICE_USER
    prompt_for_repository GITHUB_REPOSITORY
    prompt_for_runner_name GITHUB_RUNNER_NAME
    prompt_for_runner_labels GITHUB_RUNNER_LABELS
    prompt_for_personal_access_token GITHUB_PERSONAL_ACCESS_TOKEN
    RUNNER_ENV_FILE="/home/${SERVICE_USER}/.softicar/${SERVICE_SCRIPT_ENVIRONMENT_FILE}"

    SERVICE_FILE_CONTENT=$(cat $SERVICE_TEMPLATE \
                           | sed "s:%%SERVICE_USER%%:${SERVICE_USER}:" \
                           | sed "s:%%SERVICE_SCRIPT_PATH%%:${SERVICE_SCRIPT_PATH}:" \
                           | sed "s:%%RUNNER_ENV_FILE%%:${RUNNER_ENV_FILE}:" \
                           | sed "s:%%GITHUB_REPOSITORY%%:${GITHUB_REPOSITORY}:" \
                           | sed "s:%%GITHUB_RUNNER_NAME%%:${GITHUB_RUNNER_NAME}:" \
                           | sed "s:%%GITHUB_RUNNER_LABELS%%:${GITHUB_RUNNER_LABELS}:" \
                           | sed "s:%%GITHUB_PERSONAL_ACCESS_TOKEN%%:${GITHUB_PERSONAL_ACCESS_TOKEN}:" \
                         )
    sudo bash -c "echo '$SERVICE_FILE_CONTENT' > $SERVICE_FILE_DESTINATION" && \
    sudo chmod 644 $SERVICE_FILE_DESTINATION && \
    sudo systemctl daemon-reload && \
    sudo systemctl enable $SERVICE_FILE > /dev/null 2>&1 && \
    echo "Service installed and enabled. Start it with: $0 start"
  else
    echo "Service is already installed. Nothing to do."; exit 0;
  fi
}

function service_uninstall {
  if [[ -f $SERVICE_FILE_DESTINATION ]]; then
    echo "Uninstalling service..."
    sudo systemctl stop $SERVICE_FILE > /dev/null 2>&1 && \
    sudo systemctl disable $SERVICE_FILE > /dev/null 2>&1 && \
    sudo rm $SERVICE_FILE_DESTINATION && \
    sudo systemctl daemon-reload && \
    echo "Service uninstalled."
  else
    echo "Service is not installed. Nothing to do."; exit 0;
  fi
}

function service_status {
  assert_installed
  systemctl status $SERVICE_FILE
}

function service_start {
  assert_installed
  echo "Starting service..."
  sudo systemctl start $SERVICE_FILE && \
  echo "Service started."
}

function service_stop {
  assert_installed
  echo "Stopping service..."
  sudo systemctl stop $SERVICE_FILE && \
  echo "Service stopped."
}

function service_logs {
  assert_installed
  journalctl -u $SERVICE_FILE $TAILING_PARAMS
}

function assert_installed {
  [[ -f $SERVICE_FILE_DESTINATION ]] || { echo "Service is not installed. Install it with: $0 install"; exit 1; }
}

# Prompts for the name of an existing local user.
# A variable must be given as an argument. The return value is written to that variable.
function prompt_for_service_user() {
  while true; do
    echo ""
    read -erp "Enter the service user [$USER]: "
    local REPLY=${REPLY:-$USER}
    if [[ $REPLY = 'root' ]]; then echo "Please enter a non-root user."
    elif ! `id $REPLY > /dev/null 2>&1`; then echo "User '$REPLY' does not exist."
    else break
    fi
  done
  eval $1="'$REPLY'"
}

# Prompts for the name of a GitHub repository, in "SoftiCAR/some-repo" format.
# A variable must be given as an argument. The return value is written to that variable.
function prompt_for_repository() {
  while true; do
    echo ""
    read -erp "Enter the repository to build (e.g. $REPOSITORY_NAME_EXAMPLE): "
    local REPLY=${REPLY}
    if [[ -z $REPLY ]]; then echo "Please enter a repository."
    elif ! [[ $REPLY =~ $REPOSITORY_NAME_REGEX ]]; then echo "Please enter a repository name in the following format: $REPOSITORY_NAME_EXAMPLE"
    else break
    fi
  done
  eval $1="'$REPLY'"
}

# Prompts for the name of the spawned runner.
# A variable must be given as an argument. The return value is written to that variable.
function prompt_for_runner_name() {
  while true; do
    echo ""
    read -erp "Enter the name of this runner [$RUNNER_NAME_DEFAULT]: "
    local REPLY=${REPLY:-$RUNNER_NAME_DEFAULT}
    if ! [[ $REPLY =~ $RUNNER_NAME_REGEX ]]; then echo "Please enter a runner name that matches the following regex: $RUNNER_NAME_REGEX"
    else break
    fi
  done
  eval $1="'$REPLY'"
}

# Prompts for the labels of the spawned runner.
# A variable must be given as an argument. The return value is written to that variable.
function prompt_for_runner_labels() {
  echo ""
  read -erp "Enter a comma-separated list of labels for this runner [$RUNNER_LABELS_DEFAULT]: "
  local REPLY=${REPLY:-$RUNNER_LABELS_DEFAULT}
  eval $1="'$REPLY'"
}

# Prompts for a GitHub Personal Access Token.
# A variable must be given as an argument. The return value is written to that variable.
function prompt_for_personal_access_token() {
  while true; do
    read -erp $'
Enter the Personal Access Token of a build-bot user, with:
  Expire: never
  Scopes:
    repo (all)
    workflow
    read:org
    read:public_key
    read:repo_hook
    admin:org_hook
    notifications
Token: '
    local REPLY=${REPLY}
    if [[ -z $REPLY ]]; then echo "Please enter a Personal Access Token."
    else break
    fi
  done
  eval $1="'$REPLY'"
}

function print_help {
  echo "SoftiCAR GitHub Runner - Systemd Service Management Script"
  echo ""
  echo "Usage:"
  echo "  $0 [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  install          Install the service, and enable it"
  echo "  logs             Show the service logs"
  echo "                   Forwards tailing parameters to 'journalctl', e.g. '-f' or '-u'"
  echo "  start            Start the service"
  echo "  status           Show the service status"
  echo "  stop             Stop the service"
  echo "  uninstall        Uninstall the service"
}

# -------------------------------- Main Script -------------------------------- #

TAILING_PARAMS="${@:2}"

case $1 in
  "install") service_install;;
  "logs") service_logs;;
  "uninstall") service_uninstall;;
  "status") service_status;;
  "start") service_start;;
  "stop") service_stop;;
  *) print_help;;
esac
