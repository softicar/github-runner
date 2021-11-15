#!/bin/bash

# Startup script of the "nexus" container.
#
# Invoked by the init process of the container.

cd `dirname $0`

# Start the configuration script in the background
./configure.sh &

# Start Nexus
# Corresponds to the CMD in https://github.com/sonatype/docker-nexus3/blob/master/Dockerfile
# Use exec to replace the shell, so that the invoked script will properly receive signals.
exec /opt/sonatype/start-nexus-repository-manager.sh
