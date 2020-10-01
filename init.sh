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
    mkdir -p $PATH_TO_DOCKER_CONFIG/radarr
    mkdir -p $PATH_TO_DOCKER_CONFIG/sonarr
    mkdir -p $PATH_TO_DOCKER_CONFIG/bazarr
    mkdir -p $PATH_TO_DOCKER_CONFIG/mylar
    mkdir -p $PATH_TO_DOCKER_CONFIG/transmission
    echo_time "Creating directory structure...DONE"

    sudo chmod +x set-port.sh
    sudo chmod -R ug+rw $PATH_TO_DOCKER_CONFIG
    cp set-port.sh $PATH_TO_DOCKER_CONFIG/init/scripts/set-port.sh

    echo_time "Creating Workspace...DONE"
}

function cleanUp () {
    echo_time "Stopping containers.."
    docker stop $(docker ps -aq) > /dev/null
    echo_time "Stopping containers...DONE"

    echo_time "Removing all containers.."
    docker rm $(docker ps -aq)
    echo_time "Removing all containers...DONE"

    # echo_time "Removing all images.."
    # docker rmi $(docker images -q)
    # echo_time "Removing all images...DONE"
}

function startContainers () {
    echo_time "Updating and starting containers.."
    docker-compose up -d
    echo_time "Updating and starting containers...DONE"
}


function init () {
    oldPort=0
    if test -f "$PATH_TO_DOCKER_CONFIG/transmission/port.dat"; 
    then
        oldPort=$(cat $PATH_TO_DOCKER_CONFIG/transmission/port.dat)
        rm $PATH_TO_DOCKER_CONFIG/transmission/port.dat
    fi

    startContainers
    echo_time "Forwarding Port.."
    while [ ! -f $PATH_TO_DOCKER_CONFIG/transmission/port.dat ]
    do
        sleep 1
        echo_time "Checking Port Forwarding status..."
    done
    docker restart transmission
    echo_time "Forwarding Port...DONE"

    newPort=`cat $PATH_TO_DOCKER_CONFIG/transmission/port.dat`
    echo "Old Port: " $oldPort
    echo "New Port: " $newPort
}

setUpWorkspace
cleanUp
init
