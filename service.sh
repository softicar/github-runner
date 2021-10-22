#!/bin/bash

# SoftiCAR GitHub Runner - Systemd Service Management Script
#
# Facilitates installation, administration and uninstallation of the
# systemd service that manages the SoftiCAR GitHub Runner lifecycle.
#
# Run without parameters for a list of available commands.

SELF_PATH=$(cd `dirname $0` && pwd)
SERVICE_FILE=softicar-github-runner.service
SERVICE_TEMPLATE=softicar-github-runner.service-template
SERVICE_SCRIPT_PATH=$SELF_PATH/softicar-github-runner.sh
SERVICE_SCRIPT_ENVIRONMENT_FILE=softicar-github-runner.env
SERVICE_FILE_DESTINATION=/etc/systemd/system/$SERVICE_FILE

function service_install {
  if [[ ! -f $SERVICE_FILE_DESTINATION ]]; then
    [[ -f $SERVICE_TEMPLATE ]] || { echo "FATAL: Could not find the service template at $SERVICE_TEMPLATE"; exit 1; }
    [[ -f $SERVICE_SCRIPT_PATH ]] || { echo "FATAL: Could not find the service script at $SERVICE_SCRIPT_PATH"; exit 1; }

    echo "Installing service..."
    prompt_for_service_user
    RUNNER_ENV_FILE="/home/${SERVICE_USER}/.softicar/${SERVICE_SCRIPT_ENVIRONMENT_FILE}"
    SERVICE_FILE_CONTENT=$(cat $SERVICE_TEMPLATE | sed "s:%%SERVICE_USER%%:${SERVICE_USER}:" | sed "s:%%SERVICE_SCRIPT_PATH%%:${SERVICE_SCRIPT_PATH}:" | sed "s:%%RUNNER_ENV_FILE%%:${RUNNER_ENV_FILE}:")
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
    sudo systemctl disable --now $SERVICE_FILE > /dev/null 2>&1 && \
    sudo rm $SERVICE_FILE_DESTINATION && \
    sudo systemctl daemon-reload && \
    echo "Service uninstalled."
  else
    echo "Service is not installed. Nothing to do."; exit 0;
  fi
}

function service_status {
  assert_installed
  sudo systemctl status $SERVICE_FILE
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
  sudo journalctl -u $SERVICE_FILE $TAILING_PARAMS
}

function assert_installed {
  [[ -f $SERVICE_FILE_DESTINATION ]] || { echo "Service is not installed. Install it with: $0 install"; exit 1; }
}

function prompt_for_service_user() {
  while true; do
    read -p "Enter the service user [$USER]: "
    SERVICE_USER=${REPLY:-$USER}
    if [[ $SERVICE_USER = 'root' ]]; then echo "Please enter a non-root user."
    elif ! `id $SERVICE_USER > /dev/null 2>&1`; then echo "User '$SERVICE_USER' does not exist."
    else break
    fi
  done
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
