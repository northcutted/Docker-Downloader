#!/bin/bash

#Constants
PATH_TO_DOCKER_CONFIG=${1:-"~/docker-config"}
echo "Path to Docker Config: $PATH_TO_DOCKER_CONFIG"
echo_time() {
    date +"%H:%M $(printf "%s " "$@" | sed 's/%/%%/g')"
}

function setUpWorkspace () {
    echo_time "Creating Workspace.."

    echo_time "Creating directory structure.."
    mkdir -p $PATH_TO_DOCKER_CONFIG/init/scripts
    mkdir -p $PATH_TO_DOCKER_CONFIG/jackett
    mkdir -p $PATH_TO_DOCKER_CONFIG/pia
    mkdir -p $PATH_TO_DOCKER_CONFIG/pia-shared
    mkdir -p $PATH_TO_DOCKER_CONFIG/radarr
    mkdir -p $PATH_TO_DOCKER_CONFIG/sonarr
    mkdir -p $PATH_TO_DOCKER_CONFIG/bazarr
    mkdir -p $PATH_TO_DOCKER_CONFIG/mylar
    mkdir -p $PATH_TO_DOCKER_CONFIG/transmission
    echo_time "Creating directory structure...DONE"

    echo_time "Creating Workspace...DONE"
}

function cleanUp () {
    echo_time "Stopping containers.."
    docker stop $(docker ps -aq) > /dev/null
    echo_time "Stopping containers...DONE"

    echo_time "Removing all containers.."
    docker rm $(docker ps -aq)
    echo_time "Removing all containers...DONE"

    echo_time "Removing all images.."
    docker rmi $(docker images -q)
    echo_time "Removing all images...DONE"
}

function startContainers () {
    echo_time "Updating and starting containers.."
    cd $PATH_TO_DOCKER_CONFIG/init && docker-compose up -d
    echo_time "Updating and starting containers...DONE"
}


function init () {
    oldPort=0
    if test -f "$PATH_TO_DOCKER_CONFIG/transmission/forwarded_port"; 
    then
        oldPort=$(cat $PATH_TO_DOCKER_CONFIG/transmission/forwarded_port)
    fi

    startContainers
}


setUpWorkspace
cleanUp
init
