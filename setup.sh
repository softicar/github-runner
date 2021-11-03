#!/bin/bash

# SoftiCAR GitHub Runner - Setup Script
#
# Facilitates installing and uninstalling components that are required for the SoftiCAR GitHub Runner.
#
# Run without parameters for a list of available commands.

DOCKER_COMPOSE_VERSION=1.29.2
DOCKER_COMPOSE_HOME=/opt/docker-compose
DOCKER_COMPOSE_FILE=$DOCKER_COMPOSE_HOME/docker-compose-Linux-x86_64-$DOCKER_COMPOSE_VERSION
DOCKER_COMPOSE_TARGET=/usr/bin/docker-compose
SYSBOX_VERSION=0.4.1
SYSBOX_UBUNTU_RELEASE=focal
REBOOT_HINT=false
SUPPORTED_UBUNTU_RELEASES="focal"

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
    "gh") install_gh;;
    "sysbox") install_sysbox;;
    *) echo -e "Unknown component: $1\n\n"; print_help;;
  esac
}

function uninstall_component() {
  case $1 in
    "docker") uninstall_docker;;
    "docker-compose") uninstall_docker_compose;;
    "gh") uninstall_gh;;
    "sysbox") uninstall_sysbox;;
    *) echo -e "Unknown component: $1\n\n"; print_help;;
  esac
}

function install_all() {
  install_docker && \
  install_docker_compose && \
  install_gh && \
  install_sysbox

  echo ""
  print_components_status
}

function uninstall_all() {
  uninstall_sysbox && \
  uninstall_docker_compose && \
  uninstall_docker && \
  uninstall_gh

  echo ""
  print_components_status
}

function install_docker() {
  if ! is_docker_installed; then
    echo -e "\nInstalling Docker..."
    prompt_for_docker_user

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
    sudo ln -sf $DOCKER_COMPOSE_FILE $DOCKER_COMPOSE_TARGET && \
    echo "Docker-Compose installed."
  else
    echo "Docker-Compose is already installed. Nothing to do."
  fi
}

function uninstall_docker_compose() {
  if is_docker_compose_installed; then
    echo -e "\nUninstalling Docker-Compose..."
    [[ ! -L $DOCKER_COMPOSE_TARGET ]] && { echo "FATAL: Docker-Compose cannot be uninstalled because $DOCKER_COMPOSE_TARGET is not a symlink."; exit 1; }

    sudo rm $DOCKER_COMPOSE_TARGET && \
    echo "Docker-Compose uninstalled."
  else
    echo "Docker-Compose is not installed. Nothing to do."
  fi
}

function install_gh() {
  if ! is_gh_installed; then
    echo -e "\nInstalling GitHub CLI..."

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    sudo apt update && \
    sudo apt install -y gh && \
    echo "GitHub CLI installed."
  else
    echo "GitHub CLI is already installed. Nothing to do."
  fi
}

function uninstall_gh() {
  if is_gh_installed; then
    echo -e "\nUninstalling GitHub CLI..."

    sudo apt remove -y gh && \
    echo "GitHub CLI uninstalled."
  else
    echo "GitHub CLI is not installed. Nothing to do."
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

function is_docker_installed() {
  if [[ $(which docker) ]]; then true; else false; fi
}

function is_docker_compose_installed() {
  if [[ -f $DOCKER_COMPOSE_TARGET ]]; then true; else false; fi
}

function is_gh_installed() {
  if [[ $(which gh) ]]; then true; else false; fi
}

function is_sysbox_installed() {
  if [[ $(which sysbox-runc) ]]; then true; else false; fi
}

function is_running_containers() {
  if [[ $(docker ps -q) -gt 0 ]]; then true; else false; fi
}

function print_components_status() {
  echo "COMPONENT           DESCRIPTION                     INSTALLED"
  echo "docker              Docker Engine                   $(is_docker_installed && echo 'yes' || echo 'no')"
  echo "docker-compose      Docker-Compose Script           $(is_docker_compose_installed && echo 'yes' || echo 'no')"
  echo "gh                  GitHub command-line client      $(is_gh_installed && echo 'yes' || echo 'no')"
  echo "sysbox              Sysbox Docker Runtime           $(is_sysbox_installed && echo 'yes' || echo 'no')"
}

function print_reboot_hint_if_necessary() {
  if $REBOOT_HINT; then echo -e "\nPlease reboot the system."; fi
}

function prompt_for_docker_user() {
  while true; do
    read -p "Enter the user who will interact with the Docker daemon [$USER]: "
    DOCKER_USER=${REPLY:-$USER}
    if [[ $DOCKER_USER = 'root' ]]; then echo "Please enter a non-root user."
    elif ! `id $DOCKER_USER > /dev/null 2>&1`; then echo "User '$DOCKER_USER' does not exist."
    else break
    fi
  done
}

function prompt_boolean_default_yes() {
  read -p "$1 [Y/n]: " -r; REPLY=${REPLY:-"Y"};
  if [[ $REPLY =~ ^[Yy]$ ]]; then true; else false; fi
}

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
  echo "  gh                          the GitHub command-line client"
  echo "  sysbox                      the Sysbox Docker runtime"

  print_release_warning_if_necessary
}

function print_release_warning_if_necessary {
  SYSTEM_RELEASE=$(lsb_release -cs)
  if [[ ! $SUPPORTED_UBUNTU_RELEASES == *"$SYSTEM_RELEASE"* ]]; then
    echo ""
    echo "WARNING:"
    echo "The following Ubuntu releases are supported: $SUPPORTED_UBUNTU_RELEASES"
    echo "This system is based upon: $SYSTEM_RELEASE"
    echo "The setup script is not guaranteed to work properly on this system."
  fi
}

# -------------------------------- Main Script -------------------------------- #

TAILING_PARAMS="${@:2}"

case $1 in
  "install") install_components;;
  "status") print_components_status;;
  "uninstall") uninstall_components;;
  *) print_help;;
esac
