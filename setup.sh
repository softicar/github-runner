#!/bin/bash

# SoftiCAR GitHub Runner - Setup Script
#
# Facilitates installing and uninstalling components that are required for the SoftiCAR GitHub Runner.
#
# Run without parameters for a list of available commands.

source common.sh

REBOOT_HINT=false

# -------------------------------- Functions -------------------------------- #

function install_components() {
  if [[ -n $TAILING_PARAMS ]]; then
    if [[ $TAILING_PARAMS == *"all"* ]]; then
      install_all
    else
      for PARAM in $TAILING_PARAMS; do install_component $PARAM; done
    fi
  else
    prompt_boolean_default_yes "No component specified. Install all components?" && install_all
  fi

  print_reboot_hint_if_necessary
}

function uninstall_components() {
  if [[ -n $TAILING_PARAMS ]]; then
    if [[ $TAILING_PARAMS == *"all"* ]]; then
      uninstall_all
    else
      for PARAM in $TAILING_PARAMS; do uninstall_component $PARAM; done
    fi
  else
    prompt_boolean_default_no "No component specified. Uninstall all components?" && uninstall_all
  fi

  print_reboot_hint_if_necessary
}

function install_component() {
  case $1 in
    "docker") install_docker;;
    "docker-compose") install_docker_compose;;
    "service") install_service;;
    "sysbox") install_sysbox;;
    *) echo -e "Unknown component: $1\n\n"; print_help;;
  esac
}

function uninstall_component() {
  case $1 in
    "docker") uninstall_docker;;
    "docker-compose") uninstall_docker_compose;;
    "service") uninstall_service;;
    "sysbox") uninstall_sysbox;;
    *) echo -e "Unknown component: $1\n\n"; print_help;;
  esac
}

function install_all() {
  install_docker && \
  install_docker_compose && \
  install_sysbox && \
  install_service

  echo ""
  print_components_status
}

function uninstall_all() {
  uninstall_service && \
  uninstall_sysbox && \
  uninstall_docker_compose && \
  uninstall_docker

  echo ""
  print_components_status
}

function install_docker() {
  if ! is_docker_installed; then
    echo -e "\nInstalling Docker..."
    prompt_for_docker_user DOCKER_USER

    sudo apt update && \
    sudo apt install --no-install-recommends -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    sudo apt update && \
    sudo apt install -y docker-ce docker-ce-cli && \
    sudo usermod -aG docker $DOCKER_USER && \
    REBOOT_HINT=true && \
    echo "Docker installed."
  else
    echo "Docker is already installed. Nothing to do."
  fi
}

function uninstall_docker() {
  if is_docker_installed; then
    echo -e "\nUninstalling Docker..."
    is_running_containers && { echo "FATAL: Docker cannot be uninstalled as long as there are running containers."; exit 1; }

    sudo apt remove -y docker-ce docker-ce-cli && \
    REBOOT_HINT=true && \
    echo "Docker uninstalled."
  else
    echo "Docker is not installed. Nothing to do."
  fi
}

function install_docker_compose() {
  if ! is_docker_compose_installed; then
    echo -e "\nInstalling Docker-Compose..."

    sudo mkdir -p $DOCKER_COMPOSE_HOME && \
    sudo wget -O $DOCKER_COMPOSE_FILE https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 && \
    sudo chmod +x $DOCKER_COMPOSE_FILE && \
    sudo ln -sf $DOCKER_COMPOSE_FILE $DOCKER_COMPOSE_DESTINATION && \
    echo "Docker-Compose installed."
  else
    echo "Docker-Compose is already installed. Nothing to do."
  fi
}

function uninstall_docker_compose() {
  if is_docker_compose_installed; then
    echo -e "\nUninstalling Docker-Compose..."
    [[ ! -L $DOCKER_COMPOSE_DESTINATION ]] && { echo "FATAL: Docker-Compose cannot be uninstalled because $DOCKER_COMPOSE_DESTINATION is not a symlink."; exit 1; }

    sudo rm $DOCKER_COMPOSE_DESTINATION && \
    echo "Docker-Compose uninstalled."
  else
    echo "Docker-Compose is not installed. Nothing to do."
  fi
}

function install_service {
  if ! is_service_installed; then
    echo -e "\nInstalling service..."

    [[ -f $SERVICE_TEMPLATE_PATH ]] || { echo "FATAL: Could not find the service template at $SERVICE_TEMPLATE_PATH"; exit 1; }
    [[ -f $SERVICE_SCRIPT_PATH ]] || { echo "FATAL: Could not find the service script at $SERVICE_SCRIPT_PATH"; exit 1; }

    prompt_for_service_user SERVICE_USER
    prompt_for_repository GITHUB_REPOSITORY
    prompt_for_runner_name GITHUB_RUNNER_NAME
    prompt_for_runner_labels GITHUB_RUNNER_LABELS
    prompt_for_personal_access_token GITHUB_PERSONAL_ACCESS_TOKEN
    RUNNER_ENV_FILE="/home/${SERVICE_USER}/.softicar/${SERVICE_SCRIPT_ENVIRONMENT_FILE}"

    SERVICE_FILE_CONTENT=$(cat $SERVICE_TEMPLATE_PATH \
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
    echo "Service installed and enabled. Start it with: ./control.sh start"
  else
    echo "Service is already installed. Nothing to do."; exit 0;
  fi
}

function uninstall_service {
  if is_service_installed; then
    echo -e "\nUninstalling service..."
    echo "This will delete '$SERVICE_FILE_DESTINATION' which contains your Personal Access Token (PAT)."
    prompt_boolean_default_no "Are you sure?" || { echo "Aborted."; exit 1; }

    sudo systemctl stop $SERVICE_FILE > /dev/null 2>&1 && \
    sudo systemctl disable $SERVICE_FILE > /dev/null 2>&1 && \
    sudo rm $SERVICE_FILE_DESTINATION && \
    sudo systemctl daemon-reload && \
    echo "Service uninstalled."
  else
    echo "Service is not installed. Nothing to do."; exit 0;
  fi
}

function install_sysbox() {
  if ! is_sysbox_installed; then
    echo -e "\nInstalling Sysbox..."

    TEMP_DIR="$(sudo mktemp -d)" && \
    sudo wget -O $TEMP_DIR/sysbox-ce.deb https://downloads.nestybox.com/sysbox/releases/v${SYSBOX_VERSION}/sysbox-ce_${SYSBOX_VERSION}-0.ubuntu-${SYSBOX_UBUNTU_RELEASE}_amd64.deb && \
    sudo apt install -y $TEMP_DIR/sysbox-ce.deb && \
    sudo rm -rf "$TEMP_DIR" && \
    echo "Sysbox installed."
  else
    echo "Sysbox is already installed. Nothing to do."
  fi
}

function uninstall_sysbox() {
  if is_sysbox_installed; then
    echo -e "\nUninstalling Sysbox..."
    is_running_containers && { echo "FATAL: Sysbox cannot be uninstalled as long as there are running containers."; exit 1; }

    sudo apt remove -y sysbox-ce && \
    echo "Sysbox uninstalled."
  else
    echo "Sysbox is not installed. Nothing to do."
  fi
}

function is_running_containers() {
  if [[ $(docker ps -q) -gt 0 ]]; then true; else false; fi
}

function print_components_status() {
  echo "COMPONENT           DESCRIPTION                         INSTALLED"
  echo "docker              Docker Engine                       $(is_docker_installed && echo 'yes' || echo 'no')"
  echo "docker-compose      Docker-Compose Script               $(is_docker_compose_installed && echo 'yes' || echo 'no')"
  echo "service             SoftiCAR GitHub Runner service      $(is_service_installed && echo 'yes' || echo 'no')"
  echo "sysbox              Sysbox Docker Runtime               $(is_sysbox_installed && echo 'yes' || echo 'no')"
}

function print_reboot_hint_if_necessary() {
  if $REBOOT_HINT; then echo -e "\nPlease reboot this system."; fi
}

# Prompts for the name of an existing local user to interact with the Docker daemon.
# A variable must be given as an argument. The return value is written to that variable.
function prompt_for_docker_user() {
  while true; do
    read -erp "Enter the user who will interact with the Docker daemon [$USER]: "
    local REPLY=${REPLY:-$USER}
    if [[ $REPLY = 'root' ]]; then echo "Please enter a non-root user."
    elif ! `id $REPLY > /dev/null 2>&1`; then echo "User '$REPLY' does not exist."
    else break
    fi
  done
  eval $1="'$REPLY'"
}

# Prompts for the name of an existing local user to run the service.
# A variable must be given as an argument. The return value is written to that variable.
function prompt_for_service_user() {
  while true; do
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
  read -erp "Enter a comma-separated list of labels for this runner [$RUNNER_LABELS_DEFAULT]: "
  local REPLY=${REPLY:-$RUNNER_LABELS_DEFAULT}
  eval $1="'$REPLY'"
}

# Prompts for a GitHub Personal Access Token.
# A variable must be given as an argument. The return value is written to that variable.
function prompt_for_personal_access_token() {
  while true; do
    read -erp $'Enter the Personal Access Token of a build-bot user, with:
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

# Prompts for a boolean response, and defaults to "y" (yes).
# A variable must be given as an argument. Its content is used as prompt message.
function prompt_boolean_default_yes() {
  read -p "$1 [Y/n]: " -r; REPLY=${REPLY:-"Y"};
  if [[ $REPLY =~ ^[Yy]$ ]]; then true; else false; fi
}

# Prompts for a boolean response, and defaults to "n" (no).
# A variable must be given as an argument. Its content is used as prompt message.
function prompt_boolean_default_no() {
  read -p "$1 [y/N]: " -r; REPLY=${REPLY:-"N"};
  if [[ $REPLY =~ ^[Yy]$ ]]; then true; else false; fi
}

function print_help {
  echo "SoftiCAR GitHub Runner - Setup Script"
  echo ""
  echo "Usage:"
  echo "  $0 [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  install [COMPONENT]...      installs components"
  echo "  status                      shows the installation status of all components"
  echo "  uninstall [COMPONENT]...    uninstalls components"
  echo ""
  echo "Components:"
  echo "  all                         (all components)"
  echo "  docker                      the Docker Engine"
  echo "  docker-compose              the Docker-Compose script"
  echo "  service                     the SoftiCAR GitHub Runner service"
  echo "  sysbox                      the Sysbox Docker runtime"

  print_release_warning_if_necessary
}

# -------------------------------- Main Script -------------------------------- #

TAILING_PARAMS="${@:2}"

case $1 in
  "install") install_components;;
  "status") print_components_status;;
  "uninstall") uninstall_components;;
  *) print_help;;
esac
