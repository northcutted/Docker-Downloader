#!/bin/bash

# Docker-Downloader Set Up

# Ensure script is executable
# $ crontab -e
# add @reboot sleep 5 && /path/to/init.sh INSTALL_LOCATION  MEDIA_LOCATION to the crontab
# This will start the stack at boot.

INSTALL_LOCATION=${1:-"/docker_downloader_home"}
MEDIA_LOCATION=${2:-"/media/storage"}
echo "Path to Docker Config: $INSTALL_LOCATION"

echo_time() {
    date +"%H:%M $(printf "%s " "$@" | sed 's/%/%%/g')"
}

function setUpWorkspace () {
    echo_time "Creating Workspace.."

    echo_time "Creating directory structure.."
    mkdir -p $INSTALL_LOCATION/init/scripts
    mkdir -p $INSTALL_LOCATION/jackett
    mkdir -p $INSTALL_LOCATION/pia
    mkdir -p $INSTALL_LOCATION/radarr
    mkdir -p $INSTALL_LOCATION/sonarr
    mkdir -p $INSTALL_LOCATION/bazarr
    mkdir -p $INSTALL_LOCATION/mylar
    mkdir -p $INSTALL_LOCATION/transmission
    echo_time "Creating directory structure...DONE"

    if [ ! -f $INSTALL_LOCATION/docker-compose.yml ]; then
        echo_time "Installing Compose file.."
        cp docker-compose.yml.template $INSTALL_LOCATION/docker-compose.yml
        sed -i "s|INSTALL_LOCATION|$INSTALL_LOCATION|g" $INSTALL_LOCATION/docker-compose.yml
        sed -i "s|MEDIA_LOCATION|$MEDIA_LOCATION|g" $INSTALL_LOCATION/docker-compose.yml
        echo_time "Installing Compose file...DONE"
        echo "Compose file installed at $INSTALL_LOCATION/docker-compose.yml"
        echo "The install will exit, please add your PIA username and password to the file, then re-run this script."
        exit 0
    fi

    if [ ! -f $INSTALL_LOCATION/init/scripts/set-port.sh ]; then
        cp set-port.sh $INSTALL_LOCATION/init/scripts/set-port.sh
        sudo chmod +x $INSTALL_LOCATION/init/scripts/set-port.sh
    fi
    #sudo chmod -R ug+rw $INSTALL_LOCATION
    echo_time "Creating Workspace...DONE"
}

function startContainers () {
    echo_time "Updating and starting containers.."
    docker-compose -f $INSTALL_LOCATION/docker-compose.yml up --force-recreate --build -d
    docker image prune -f
    echo_time "Updating and starting containers...DONE"
}

setUpWorkspace
oldPort=0
if test -f "$INSTALL_LOCATION/transmission/port.dat";
then
    oldPort=$(cat $INSTALL_LOCATION/transmission/port.dat)
    rm $INSTALL_LOCATION/transmission/port.dat
fi

startContainers
echo_time "Forwarding Port.."
while [ ! -f $INSTALL_LOCATION/transmission/port.dat ]
do
    sleep 1
    echo_time "Checking Port Forwarding status..."
done
docker restart transmission
echo_time "Forwarding Port...DONE"

newPort=`cat $INSTALL_LOCATION/transmission/port.dat`
echo "Old Port: " $oldPort
echo "New Port: " $newPort