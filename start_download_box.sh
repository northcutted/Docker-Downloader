#!/bin/bash
# Download Box Set Up

# To run when box starts:
# Make sure script is executable
# run 'crontab -e'
# add '@reboot sleep 10 && /home/downloadbox/docker-config/init/startseedbox.sh' to the crontab
# ????
# profit

#Constants
PATH_TO_DOCKER_CONFIG=${1:="./docker-config"}
PIA_USER=$2
PIA_PASSWORD=$3
PATH_TO_LOG_FILE=$PATH_TO_DOCKER_CONFIG/download-box.log   
# Logger
exec 2>&1 | tee ${PATH_TO_LOG_FILE}

# Util Function to log with time stampts
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

    setUpDockerComposeFile
    setUpPortForwardScript

    echo_time "Creating Workspace...DONE"
}

function setUpDockerComposeFile () {
    echo_time "Checking for docker-compose.yml file.."
    if [ ! -f $PATH_TO_DOCKER_CONFIG/init/docker-compose.yml ];
    then
        echo_time "No docker-compose.yml file found."
        echo_time "Downloading docker-compose.yml file to $PATH_TO_DOCKER_CONFIG/init/docker-compose.yml.."
        wget --output-document $PATH_TO_DOCKER_CONFIG/init/docker-compose.yml https://raw.githubusercontent.com/northcutted/Docker-Downloader/master/docker-compose.yml
        echo_time "Downloading docker-compose.yml file...DONE"

        echo_time "Updating PIA Credientials.."
        sed -i "s/      - USER=/      - USER=$PIA_USER/g" $PATH_TO_DOCKER_CONFIG/init/docker-compose.yml
        sed -i "s/      - PASSWORD=/      - PASSWORD=$PIA_PASSWORD/g" $PATH_TO_DOCKER_CONFIG/init/docker-compose.yml
        echo_time "Updating PIA Credintials...DONE"

        echo_time "Updating docker-compose.yml to reflect user paths.."
        sed -i "s|~/docker-config|$PATH_TO_DOCKER_CONFIG|g" $PATH_TO_DOCKER_CONFIG/init/docker-compose.yml
        echo_time "Updating docker-compose.yml to reflect user paths...DONE"

    fi
    echo_time "Checking for docker-compose.yml file...DONE"
}

function setUpPortForwardScript () {
    echo_time "Checking for port forwarding script.."
    if [ ! -f $PATH_TO_DOCKER_CONFIG/init/scripts/set-port.sh ];
    then
        echo_time "No set-port.sh file found."
        echo_time "Downloading set-port.sh file to $PATH_TO_DOCKER_CONFIG/init/scripts/set-port.sh.."
        wget --output-document $PATH_TO_DOCKER_CONFIG/init/scripts/set-port.sh https://raw.githubusercontent.com/northcutted/Docker-Downloader/master/set-port.sh
        echo_time "Downloading set-port.sh file...DONE"
    fi
    echo_time "Checking for port forwarding script...DONE"
}

function cleanUp () {
    # Clean up Old Containers
    echo_time "Stopping containers.."
    docker stop jackett &&
    docker stop bazarr &&
    docker stop sonarr &&
    docker stop radarr &&
    docker stop mylar &&
    docker stop transmission &&
    docker stop pia > /dev/null
    echo_time "Stopping containers...DONE"

    echo_time "Pruning all containers.."
    docker container prune -f
    echo_time "Pruning all containers...DONE"

    echo_time "Pruning all images.."
    docker image prune -f
    echo_time "Pruning all images...DONE"
}

function startContainers () {
    # Start Services
    echo_time "Updating and starting containers.."
    cd $PATH_TO_DOCKER_CONFIG/init && docker-compose pull && docker-compose up -d
    echo_time "Updating and starting containers...DONE"
}

function setup () {
    #Stop Transmission
    echo_time "Stopping transmission.."
    docker stop sonarr
    docker stop radarr
    docker stop mylar
    docker stop transmission
    echo_time "Stopping transmission...DONE"
    echo_time "Removing transmission.."
    docker rm transmission
    echo_time "Removing transmission...DONE"
    
    # Wait until VPN is healthy (NOTE: Helath check too slow, sleep 30 sec until fixed)
    # If this is the case then "docker inspect pia | grep '"Status": "healthy"'" returns exit code: 0
    # docker inspect pia | grep '"Status": "healthy"'
    # is_healthy=$?
    # # Until $is_healthy equals zero...
    # until [ $is_healthy -eq 0 ]
    # do
    #     # Check the health of the container every 5 seconds until it is healthy
    #     echo_time "Waiting for PIA status to become healthy.."
    #     sleep 5
    #     docker inspect pia | grep '"Status": "healthy"'
    #     is_healthy=$?
    # done
    echo_time "Waiting for PIA status to become healthy.."
    sleep 30
    echo_time "Waiting for PIA status to become healthy...DONE"

    # Start Transmission with pia port written to file
    cd $PATH_TO_DOCKER_CONFIG/init && docker-compose up -d
}

function init () {
    oldPort=0
    if test -f "$PATH_TO_DOCKER_CONFIG/transmission/forwarded_port"; 
    then
        oldPort=$(cat $PATH_TO_DOCKER_CONFIG/transmission/forwarded_port)
    fi

    startContainers
    echo_time "Forwarding Port.."
    until [ -f $PATH_TO_DOCKER_CONFIG/transmission/forwarded_port ]
    do
        sleep 1
        echo_time "Checking Port Forwarding status..."
    done
    echo_time "Forwarding Port...DONE"

    newPort=`cat $PATH_TO_DOCKER_CONFIG/transmission/forwarded_port`
    echo "Old Port: " $oldPort
    echo "New Port: " $newPort

    if [ $oldPort -eq $newPort ] 
    then
        echo_time "PIA Failed to forward the port. Restarting..."
        # Clean up Old Containers
        echo_time "Stopping all containers.."
        docker stop $(docker ps -aq)
        echo_time "Stopping all containers...DONE"
        # Restart Process
        init
    else
        setup
        echo_time "DownloadBox Started!"
    fi
}

setUpWorkspace
cleanUp
init
