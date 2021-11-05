#!/bin/bash

# SoftiCAR GitHub Runner - Systemd Service Control Script
#
# Facilitates administration of the systemd service that manages the SoftiCAR GitHub Runner lifecycle.
#
# Run without parameters for a list of available commands.

source common.sh

# -------------------------------- Functions -------------------------------- #

function service_logs {
  assert_service_installed
  journalctl -u $SERVICE_FILE $TAILING_PARAMS
}

function service_status {
  assert_service_installed
  systemctl status $SERVICE_FILE
}

function service_start {
  assert_service_installed
  echo "Starting service..."
  assert_docker_installed
  assert_docker_compose_installed
  assert_sysbox_installed

  sudo systemctl start $SERVICE_FILE && \
  echo "Service started."
}

function service_stop {
  assert_service_installed
  echo "Stopping service..."

  sudo systemctl stop $SERVICE_FILE && \
  echo "Service stopped."
}

function print_help {
  echo "SoftiCAR GitHub Runner - Systemd Service Control Script"
  echo ""
  echo "Usage:"
  echo "  $0 [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  logs             Show the service logs"
  echo "                   Tailing parameters are forwarded to 'journalctl', e.g. '-f' or '-r'"
  echo "  start            Start the service"
  echo "  status           Show the service status"
  echo "  stop             Stop the service"
}

# -------------------------------- Main Script -------------------------------- #

TAILING_PARAMS="${@:2}"

case $1 in
  "logs") service_logs;;
  "status") service_status;;
  "start") service_start;;
  "stop") service_stop;;
  *) print_help;;
esac
