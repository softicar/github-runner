#!/bin/bash

# Validate environment variables
[[ -z "$GITHUB_PERSONAL_TOKEN" ]] && { echo "FATAL: GITHUB_PERSONAL_TOKEN must not be empty." ; exit 1; }
[[ -z "$GITHUB_REPOSITORY" ]] && { echo "FATAL: GITHUB_REPOSITORY must not be empty." ; exit 1; }
[[ -z "$GITHUB_RUNNER_NAME" ]] && { echo "FATAL: GITHUB_RUNNER_NAME must not be empty." ; exit 1; }

AUTH_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token"
REGISTRATION_URL="https://github.com/${GITHUB_REPOSITORY}"

# Generates a new runner token, using a personal access token.
generate_runner_token() {
  echo "Generating runner token..."
  TOKEN_RESPONSE=$(curl -sX POST -H "Authorization: token ${GITHUB_PERSONAL_TOKEN}" "${AUTH_URL}")
  RUNNER_TOKEN=$(echo "${TOKEN_RESPONSE}" | jq .token --raw-output)

  if [ "${RUNNER_TOKEN}" == "null" ]
  then
    echo "Failed to generate runner token: ${TOKEN_RESPONSE}"
    exit 1
  fi

  echo "Runner token generated."
}

# Registers a new runner.
register_runner() {
  echo "Registering runner..."
  RUNNER_ID=${GITHUB_RUNNER_NAME}_$(openssl rand -hex 6)
  generate_runner_token
  ./config.sh \
    --name "${RUNNER_ID}" \
    --labels "${GITHUB_RUNNER_LABELS}" \
    --token "${RUNNER_TOKEN}" \
    --url "${REGISTRATION_URL}" \
    --unattended \
    --ephemeral
  echo "Runner ${RUNNER_ID} registered."
}

# Unregisters the previously registered runner.
unregister_runner() {
  echo "Unregistering runner..."
  ./config.sh remove --unattended --token "${RUNNER_TOKEN}"
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

echo "Starting Docker..."
sudo service docker start
echo "Docker started."

trap_signals
register_runner

echo "Starting runner version $(./run.sh --version)..."
./run.sh "$*"
echo "Runner terminated."
