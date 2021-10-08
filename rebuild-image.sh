#!/bin/bash

# TODO integrate this into softicar-github-runner.sh, complete with auto-updates by querying https://api.github.com/repos/actions/runner/releases before each restart. should be quite simple.

docker build -t softicar/softicar-github-runner .
docker image prune -f
