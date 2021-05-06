#!/usr/bin/env bash

SCRIPT_VERSION=1.3.0

# Usage / help.

USAGE="Bring up Senzing web application.
Usage:
    $(basename "$0") project-dir
Where:
    project-dir = Path to new or existing Senzing project
Version:
    ${SCRIPT_VERSION}
"

SENZING_DOCKER_IMAGE_VERSION_G2LOADER=1.4.1
SENZING_DOCKER_IMAGE_VERSION_INIT_CONTAINER=1.6.9
SENZING_DOCKER_IMAGE_VERSION_SENZING_DEBUG=1.3.5
SENZING_DOCKER_IMAGE_VERSION_WEB_APP_DEMO=2.1.1
SENZING_DOCKER_IMAGE_VERSION_YUM=1.1.4

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

# Given a relative path, find the fully qualified path.

find_realpath() {
    OURPWD=$PWD
    cd "$(dirname "$1")"
    LINK=$(readlink "$(basename "$1")")
    while [ "$LINK" ]; do
        cd "$(dirname "$LINK")"
        LINK=$(readlink "$(basename "$1")")
    done
    REALPATH="$PWD/$(basename "$1")"
    cd "$OURPWD"
    echo "$REALPATH"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

# Parse positional input parameters.

SENZING_PROJECT_DIR=$1

# Determine operating system running this script.

UNAME_VALUE="$(uname -s)"
case "${UNAME_VALUE}" in
    Linux*)     HOST_MACHINE_OS=Linux;;
    Darwin*)    HOST_MACHINE_OS=Mac;;
    CYGWIN*)    HOST_MACHINE_OS=Cygwin;;
    MINGW*)     HOST_MACHINE_OS=MinGw;;
    *)          HOST_MACHINE_OS="UNKNOWN:${UNAME_VALUE}"
esac

# Verify input.

if [[ ( -z ${SENZING_PROJECT_DIR} ) ]]; then
    echo "${USAGE}"
    echo "ERROR: Missing project-dir."
    exit 1
fi

# Verify environment: curl, docker, python3.

if [[ ( ! -n "$(command -v curl)" ) ]]; then
    echo "ERROR: curl is required."
    echo "See https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-curl.md"
    exit 1
fi

if [[ ( ! -n "$(command -v docker)" ) ]]; then
    echo "ERROR: docker is required."
    echo "See https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-docker.md"
    exit 1
fi

if [[ ( -n "$(command -v python3)" ) ]]; then
    PYTHON3_INSTALLED=1
else
    echo "WARNING: python3 is not installed."
    echo "WARNING: Files will not be created in docker-bin directory."
    echo "See https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-python-3.md"
fi

# Determine if Docker is running.

if [[ ( ${UNAME_VALUE:0:6} != "CYGWIN" ) ]]; then
    sudo -p "To run Docker, sudo access is required.  Please enter your password:  " docker info >> /dev/null 2>&1
    DOCKER_RETURN_CODE=$?
    if [[ ( "${DOCKER_RETURN_CODE}" != "0" ) ]]; then
        echo "ERROR: Docker is not running."
        echo "Please start Docker."
        exit 1
    fi
else
    echo "To run sudo docker, You may prompted for your password."
fi

# Configuration via environment variables.

SENZING_ENVIRONMENT_SUBCOMMAND=${SENZING_ENVIRONMENT_SUBCOMMAND:-"add-docker-support-macos"}
TRUTH_SET_1_DATA_SOURCE_NAME=${SENZING_TRUTH_SET_1_DATA_SOURCE_NAME:-"CUSTOMER"}
TRUTH_SET_2_DATA_SOURCE_NAME=${SENZING_TRUTH_SET_2_DATA_SOURCE_NAME:-"WATCHLIST"}

# Synthesize variables.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
SENZING_PROJECT_DIR_REALPATH=$(find_realpath ${SENZING_PROJECT_DIR})
HORIZONTAL_RULE="=============================================================================="
SENZING_DATA_DIR=${SENZING_PROJECT_DIR_REALPATH}/data
SENZING_DOCKER_BIN_DIR=${SENZING_PROJECT_DIR_REALPATH}/docker-bin
SENZING_ETC_DIR=${SENZING_PROJECT_DIR_REALPATH}/docker-etc
SENZING_G2_DIR=${SENZING_PROJECT_DIR_REALPATH}/g2
SENZING_HISTORY_FILE=${SENZING_PROJECT_DIR_REALPATH}/.senzing/history.log
SENZING_PROJECT_NAME=$(basename "${SENZING_PROJECT_DIR_REALPATH}")
SENZING_VAR_DIR=${SENZING_PROJECT_DIR_REALPATH}/var
TERMINAL_TTY=/dev/tty

# If project directory doesn't exist, this is a first time installation.

if [[ ( ! -d ${SENZING_PROJECT_DIR} ) ]]; then
    FIRST_TIME_INSTALL=1

# If a project directory does exist, ask if it should be updated.
# Reason: If someone is doing a demo, they shouldn't have to wait for an update.

else

    read -t 30 -p "Would you like to detect and install updates?  [y/N] " UPDATES_RESPONSE
    case ${UPDATES_RESPONSE} in
        [Yy]* ) PERFORM_UPDATES=1;;
        * ) ;;
    esac
    echo ""
fi

# Tasks for first time installation or requested update.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) \
   || ( ! -z ${PERFORM_UPDATES} ) \
   ]]; then

    # Ask for EULA acceptance.

    echo "The Senzing end user license agreement can be found at"
    echo "https://senzing.com/end-user-license-agreement"
    echo ""
    read -p "Do you accept the license terms and conditions?  [y/N] " EULA_RESPONSE
    case ${EULA_RESPONSE} in
        [Yy]* ) SENZING_ACCEPT_EULA=I_ACCEPT_THE_SENZING_EULA;;
        * ) echo "EULA not accepted. Must enter 'Y' to accept EULA."
            exit 1;;
    esac

    # Ask for log visibility.

    read -p "Show logging in this terminal window?  [y/N] " LOG_RESPONSE
    case ${LOG_RESPONSE} in
        [Yy]* ) LOG_TO_TERMINAL=1;;
        * ) ;;
    esac

fi

# Tasks for first time install instructions.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) ]]; then
    mkdir -p ${SENZING_PROJECT_DIR}/.senzing
fi

# Configure log visibility.

if [[ ( ! -z ${LOG_TO_TERMINAL} ) ]]; then
    exec > >(tee -i -a ${SENZING_HISTORY_FILE})
else
    if [[ ( ! -z ${FIRST_TIME_INSTALL} ) \
       || ( ! -z ${PERFORM_UPDATES} ) \
       ]]; then
        echo "To view log, run:"
        echo "tail -f ${SENZING_HISTORY_FILE}"
    fi
    exec >> ${SENZING_HISTORY_FILE} 2>&1
fi

# Make entry in history log.

echo ""
echo "${HORIZONTAL_RULE}"
echo "${HORIZONTAL_RULE:0:2} Start time: $(date)"
echo "${HORIZONTAL_RULE:0:2} Script version: ${SCRIPT_VERSION}"
echo "${HORIZONTAL_RULE}"
echo ""
echo "Operating system running script: ${HOST_MACHINE_OS}"

# If first time or update, pull docker images.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) \
   || ( ! -z ${PERFORM_UPDATES} ) \
   ]]; then

    # Pull docker images.

    echo "Pulling Docker images." > ${TERMINAL_TTY}

    sudo docker pull senzing/g2loader:${SENZING_DOCKER_IMAGE_VERSION_G2LOADER}
    echo -ne 'Pulling ...\r' > ${TERMINAL_TTY}
    sudo docker pull senzing/init-container:${SENZING_DOCKER_IMAGE_VERSION_INIT_CONTAINER}
    echo -ne 'Pulling ......\r' > ${TERMINAL_TTY}
    sudo docker pull senzing/senzing-debug:${SENZING_DOCKER_IMAGE_VERSION_SENZING_DEBUG}
    echo -ne 'Pulling .........\r' > ${TERMINAL_TTY}
    sudo docker pull senzing/web-app-demo:${SENZING_DOCKER_IMAGE_VERSION_WEB_APP_DEMO}
    echo -ne 'Pulling ............\r' > ${TERMINAL_TTY}
    sudo docker pull senzing/yum:${SENZING_DOCKER_IMAGE_VERSION_YUM}
    echo -ne 'Pulling ...............\r' > ${TERMINAL_TTY}

fi

# If new project or update requested, install/update Senzing.

if [[ ( ! -e ${SENZING_G2_DIR}/g2BuildVersion.json ) \
   || ( ! -e ${SENZING_DATA_DIR}/terms.ibm ) \
   || ( ! -z ${PERFORM_UPDATES} ) \
   ]]; then

    if [[ ( ! -z ${PERFORM_UPDATES} ) ]]; then
        echo "Performing updates."
        echo "Determining if a new version of Senzing exists."  > ${TERMINAL_TTY}
    fi

    # Determine version of senzingapi on public repository.

    sudo docker run \
      --privileged \
      --rm \
      senzing/yum:${SENZING_DOCKER_IMAGE_VERSION_YUM} list senzingapi > ${SENZING_PROJECT_DIR}/yum-list-senzingapi.txt

    SENZING_G2_CURRENT_VERSION=$(grep senzingapi ${SENZING_PROJECT_DIR}/yum-list-senzingapi.txt | awk '{print $2}' | awk -F \- {'print $1'})
    SENZING_G2_DIR_CURRENT=${SENZING_G2_DIR}-${SENZING_G2_CURRENT_VERSION}
    rm ${SENZING_PROJECT_DIR}/yum-list-senzingapi.txt

    # Determine version of senzingdata on public repository.

    sudo docker run \
      --privileged \
      --rm \
      senzing/yum:${SENZING_DOCKER_IMAGE_VERSION_YUM} list senzingdata-v2 > ${SENZING_PROJECT_DIR}/yum-list-senzingdata.txt

    SENZING_DATA_CURRENT_VERSION=$(grep senzingdata ${SENZING_PROJECT_DIR}/yum-list-senzingdata.txt | awk '{print $2}' | awk -F \- {'print $1'})
    SENZING_DATA_DIR_CURRENT=${SENZING_DATA_DIR}-${SENZING_DATA_CURRENT_VERSION}
    rm ${SENZING_PROJECT_DIR}/yum-list-senzingdata.txt

    # If new version available, install it.

    if [[ ( ! -e ${SENZING_G2_DIR_CURRENT} ) ]]; then

        echo "$(date) Installing SenzingApi ${SENZING_G2_CURRENT_VERSION}"
        echo "Installing SenzingApi ${SENZING_G2_CURRENT_VERSION}" > ${TERMINAL_TTY}
        echo "Depending on network speeds, this may take up to 15 minutes." > ${TERMINAL_TTY}
        echo "To view progress, run:" > ${TERMINAL_TTY}
        echo "tail -f ${SENZING_HISTORY_FILE}" > ${TERMINAL_TTY}

        # If symbolic links exist, move them.
        # If successful, they will be removed later.
        # If unsuccessful, they will be restored.

        TIMESTAMP=$(date +%s)

        if [[ ( -e ${SENZING_G2_DIR} ) ]]; then
            mv ${SENZING_G2_DIR} ${SENZING_G2_DIR}-bak-${TIMESTAMP}
        fi

        if [[ ( -e ${SENZING_DATA_DIR} ) ]]; then
            mv ${SENZING_DATA_DIR} ${SENZING_DATA_DIR}-bak-${TIMESTAMP}
        fi

        # Download Senzing binaries.

        sudo docker run \
          --env SENZING_ACCEPT_EULA=${SENZING_ACCEPT_EULA} \
          --privileged \
          --rm \
          --volume ${SENZING_PROJECT_DIR_REALPATH}:/opt/senzing \
          senzing/yum:${SENZING_DOCKER_IMAGE_VERSION_YUM}

        # DEBUG: local install.

#        sudo docker run \
#            --privileged \
#            --env SENZING_ACCEPT_EULA=${SENZING_ACCEPT_EULA} \
#            --rm \
#            --volume ${SENZING_PROJECT_DIR_REALPATH}:/opt/senzing \
#            --volume ~/Downloads:/data \
#            senzing/yum:${SENZING_DOCKER_IMAGE_VERSION_YUM} -y localinstall /data/senzingapi-2.0.0-20197.x86_64.rpm /data/senzingdata-v2-2.0.0-1.x86_64.rpm

        sudo chown -R $(id -u):$(id -g) ${SENZING_PROJECT_DIR_REALPATH}

        # Create symbolic links to versioned directories.
        # Tricky code: Also accounting for a failed/cancelled YUM install.

        pushd ${SENZING_PROJECT_DIR_REALPATH}

        # Move "g2" to "g2-M.m.P" directory and make "g2" symlink.

        if [[ ( -e ${SENZING_G2_DIR} ) ]]; then
            mv g2 g2-${SENZING_G2_CURRENT_VERSION}
            ln -s g2-${SENZING_G2_CURRENT_VERSION} g2
            rm ${SENZING_G2_DIR}-bak-${TIMESTAMP}

        else
            mv ${SENZING_G2_DIR}-bak-${TIMESTAMP} ${SENZING_G2_DIR}
        fi

        # Move "data" to "data-M.m.P" directory, remove the version subdirectory, make "data" symlink.

        if [[ ( ! -e ${SENZING_DATA_DIR_CURRENT} ) ]]; then
            mv data data-backup
            mv data-backup/2.0.0 data-${SENZING_DATA_CURRENT_VERSION}
            rmdir data-backup
            ln -s data-${SENZING_DATA_CURRENT_VERSION} data
            rm ${SENZING_DATA_DIR}-bak-${TIMESTAMP}

        else
            rm -rf ${SENZING_DATA_DIR}
            mv ${SENZING_DATA_DIR}-bak-${TIMESTAMP} ${SENZING_DATA_DIR}
        fi

        popd

    fi # if [[ ( ! -e ${SENZING_G2_DIR_CURRENT} ) ]]; then

fi  # if FIRST_TIME_INSTALL or PERFORM_UPDATES

# If needed, populate docker-bin directory.

DOCKER_ENVIRONMENT_VARS_FILENAME=${SENZING_DOCKER_BIN_DIR}/docker-environment-vars.sh

if [[ ( ! -e ${DOCKER_ENVIRONMENT_VARS_FILENAME} ) ]]; then

    # If needed, add senzing-environment.py.

    SENZING_ENVIRONMENT_FILENAME=${SENZING_PROJECT_DIR_REALPATH}/senzing-environment.py

    if [[ ( ! -e ${SENZING_ENVIRONMENT_FILENAME} ) ]]; then

        curl -X GET \
            --output ${SENZING_ENVIRONMENT_FILENAME} \
            https://raw.githubusercontent.com/Senzing/senzing-environment/master/senzing-environment.py

        chmod +x ${SENZING_ENVIRONMENT_FILENAME}

    fi

    # Populate docker-bin and docker-etc directories.

    if [[ ( ! -z ${PYTHON3_INSTALLED} ) ]]; then
        ${SENZING_ENVIRONMENT_FILENAME} ${SENZING_ENVIRONMENT_SUBCOMMAND} --project-dir ${SENZING_PROJECT_DIR}

        # Create private network.

        sudo docker network create senzing-up
        echo "export SENZING_NETWORK_PARAMETER=\"--net senzing-up\"" >> ${SENZING_PROJECT_DIR}/docker-bin/docker-environment-vars.sh
    fi

    if [[ ( ! -d ${SENZING_DOCKER_BIN_DIR} ) ]]; then
        mkdir -p ${SENZING_DOCKER_BIN_DIR}
    fi

    mv ${SENZING_ENVIRONMENT_FILENAME} ${SENZING_DOCKER_BIN_DIR}

fi

# If needed, initialize etc and var directories.

if [[ ( ! -e ${SENZING_ETC_DIR} ) ]]; then

    echo "Creating ${SENZING_ETC_DIR}" > ${TERMINAL_TTY}
    echo "Initializing Senzing configuration." > ${TERMINAL_TTY}

    sudo docker run \
        --privileged \
        --rm \
        --user 0 \
        --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
        --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
        --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
        --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
        senzing/init-container:${SENZING_DOCKER_IMAGE_VERSION_INIT_CONTAINER}

    sudo chown -R $(id -u):$(id -g) ${SENZING_PROJECT_DIR_REALPATH}

fi

# If requested, update Senzing database schema and configuration.

if [[ ( ! -z ${PERFORM_UPDATES} ) ]]; then

    echo "Updating Senzing database schema." > ${TERMINAL_TTY}

    sudo docker run \
        --privileged \
        --rm \
        --user $(id -u):$(id -g) \
        --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
        --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
        --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
        --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
        senzing/senzing-debug:${SENZING_DOCKER_IMAGE_VERSION_SENZING_DEBUG} \
            /opt/senzing/g2/bin/g2dbupgrade \
                -c /etc/opt/senzing/G2Module.ini \
                -a

    echo "Updating Senzing configuration." > ${TERMINAL_TTY}

    # Remove obsolete GTC files.

    sudo rm --force ${SENZING_G2_DIR}/resources/config/g2core-config-upgrade-1.9-to-1.10.gtc

    # Apply all G2C files in alphabetical order.

    for FULL_PATHNAME in ${SENZING_G2_DIR}/resources/config/*; do
        FILENAME=$(basename ${FULL_PATHNAME})

        echo ".. Verifying ${FILENAME}"

        sudo docker run \
            --privileged \
            --rm \
            --user $(id -u):$(id -g) \
            --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
            --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
            --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
            --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
            senzing/senzing-debug:${SENZING_DOCKER_IMAGE_VERSION_SENZING_DEBUG} \
                /opt/senzing/g2/python/G2ConfigTool.py \
                    -c /etc/opt/senzing/G2Module.ini \
                    -f /opt/senzing/g2/resources/config/${FILENAME}

        RETURN_CODE=$?

        echo ".... return code: ${RETURN_CODE}"
    done

fi

# Load Senzing Model with sample data.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) ]]; then
    echo "Loading sample data." > ${TERMINAL_TTY}

    # Create file:  truthset-project.csv

    cat <<EOT > ${SENZING_VAR_DIR}/truthset-project.csv
DATA_SOURCE,FILE_FORMAT,FILE_NAME
${TRUTH_SET_1_DATA_SOURCE_NAME},CSV,/opt/senzing/g2/python/demo/truth/truthset-person-v1-set1-data.csv
${TRUTH_SET_2_DATA_SOURCE_NAME},CSV,/opt/senzing/g2/python/demo/truth/truthset-person-v1-set2-data.csv
EOT

    # Invoke G2Loader.py via Docker container to load files into Senzing Model.

    sudo docker run \
        --privileged \
        --rm \
        --user $(id -u):$(id -g) \
        --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
        --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
        --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
        --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
        senzing/g2loader:${SENZING_DOCKER_IMAGE_VERSION_G2LOADER} \
            -p /var/opt/senzing/truthset-project.csv

fi

# Print prolog.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) ]]; then
    echo " $(date) Installation is complete."
    echo "${HORIZONTAL_RULE:0:2} Installation is complete." > ${TERMINAL_TTY}
elif [[ ( ! -z ${PERFORM_UPDATES} ) ]]; then
    echo " $(date) Update is complete."
    echo "${HORIZONTAL_RULE:0:2} Update is complete." > ${TERMINAL_TTY}
fi

# Run web-app Docker container.

${SENZING_PROJECT_DIR_REALPATH}/docker-bin/senzing-webapp-demo.sh init  > ${TERMINAL_TTY}

# Print epilog.

echo "${HORIZONTAL_RULE:0:2} Project location: ${SENZING_PROJECT_DIR_REALPATH}" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE:0:2}" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE:0:2} To stop docker formation, run:" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE:0:2} ${SENZING_PROJECT_DIR_REALPATH}/docker-bin/senzing-webapp-demo.sh down" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE:0:2}" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE:0:2} To restart docker formation, run:" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE:0:2} ${SENZING_PROJECT_DIR_REALPATH}/docker-bin/senzing-webapp-demo.sh up" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE:0:2}" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE:0:2} For more information, see:" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE:0:2} https://senzing.github.io/senzing-up" > ${TERMINAL_TTY}
echo "${HORIZONTAL_RULE}" > ${TERMINAL_TTY}

echo "$(date) Done."
