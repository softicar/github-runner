#!/bin/bash

# TODO describe this script

docker build -t softicar/softicar-github-runner .
docker image prune -f
