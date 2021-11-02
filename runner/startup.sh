#!/bin/bash

# Validate environment variables
[[ -z "$GITHUB_RUNNER_TOKEN" ]] && { echo "FATAL: GITHUB_RUNNER_TOKEN must be defined." ; exit 1; }
[[ -z "$GITHUB_REPOSITORY" ]] && { echo "FATAL: GITHUB_REPOSITORY must be defined." ; exit 1; }
[[ -z "$GITHUB_RUNNER_NAME" ]] && { echo "FATAL: GITHUB_RUNNER_NAME must be defined." ; exit 1; }

# Registers a new runner.
register_runner() {
  echo "Registering runner..."
  local registration_url="https://github.com/${GITHUB_REPOSITORY}"
  local runner_name=${GITHUB_RUNNER_NAME}_$(openssl rand -hex 6)
  ./config.sh \
    --url "${registration_url}" \
    --name "${runner_name}" \
    --labels "${GITHUB_RUNNER_LABELS}" \
    --token "${GITHUB_RUNNER_TOKEN}" \
    --unattended \
    --ephemeral
  echo "Runner ${runner_name} registered."
}

# Unregisters the previously registered runner.
unregister_runner() {
  echo "Unregistering runner..."
  ./config.sh remove --unattended --token "${GITHUB_RUNNER_TOKEN}"
  echo "Runner unregistered."
}

# Traps various signals that could terminate this script, to perform cleanup operations.
# Exits with 128+n for any trapped signal with an ID of n (cf. `kill -l`).
trap_signals() {
  trap 'unregister_runner; exit 130;' SIGINT
  trap 'unregister_runner; exit 143;' SIGTERM
  # `docker stop` seems to generate this instead of SIGTERM
  trap 'unregister_runner; exit 165;' SIGRTMIN+3
}

# -------- Main Script -------- #

sudo service docker start
trap_signals
register_runner

echo "Starting runner version $(./run.sh --version)..."
./run.sh "$*"
echo "Runner terminated."
