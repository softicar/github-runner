#!/bin/bash

# This script facilitates starting and stopping the Sonatype Nexus Repository Manager 3.
#
# Besides other tasks, Sonatype Nexus Repository Manager 3 can be employed as a proxy to
# cache Maven artifacts and Docker images. There are has many other usecases.
#
# This script employs the `sonatype/nexus3` Docker image. The script automatically creates
# a dedicated Docker volume on the host to store data persistently.
#
# For reference: https://hub.docker.com/r/sonatype/nexus3/

CONTAINER_NAME="nexus"
IMAGE_NAME="sonatype/nexus3"
VOLUME_NAME="nexus-data"

MAVEN_PROXY_PORT=8081
DOCKER_PROXY_PORT=8123

function is_running {
	[ "`docker ps -q -f name=$CONTAINER_NAME`" != "" ]
}

function volume_exists {
	[ "`docker volume ls -q -f name=$VOLUME_NAME`" != "" ]
}

function print_status {
	if is_running
	then
		echo "Container '$CONTAINER_NAME' is running."
	else
		echo "Container '$CONTAINER_NAME' is not running."
	fi

	if volume_exists
	then
		echo "Data volume '$VOLUME_NAME' exists."
	else
		echo "Data volume '$VOLUME_NAME' does not exists."
	fi
}

function create_volume {
	echo "Creating data volume '$VOLUME_NAME'."
	docker volume create --name $VOLUME_NAME
}

function start_nexus {
	echo "Starting container '$CONTAINER_NAME'..."
	docker run \
		--rm -d \
		--name $CONTAINER_NAME \
		-v $VOLUME_NAME:/nexus-data \
		-p $MAVEN_PROXY_PORT:$MAVEN_PROXY_PORT \
		-p $DOCKER_PROXY_PORT:$DOCKER_PROXY_PORT \
		$IMAGE_NAME
}

function stop_nexus {
	echo "Stopping container '$CONTAINER_NAME'..."
	docker stop --time=120 $CONTAINER_NAME
}

if [ "$1" == "start" ]
then
	print_status
	volume_exists || create_volume
	is_running || start_nexus
elif [ "$1" == "stop" ]
then
	print_status
	is_running && stop_nexus
elif [ "$1" == "status" ]
then
	print_status
else
	echo "Usage: $0 start|stop|status"
fi

