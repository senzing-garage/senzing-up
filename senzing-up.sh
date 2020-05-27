#!/usr/bin/env bash

# Usage / help.

USAGE="Bring up Senzing web application.
Usage:
    $(basename "$0") project-dir
Where:
    project-dir = Path to new or existing Senzing project
"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

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

perform_docker_pulls() {
    docker pull senzing/init-container:latest
    docker pull senzing/senzing-debug:latest
    docker pull senzing/web-app-demo:latest
    docker pull senzing/yum:latest
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

# Parse positional input parameters.

SENZING_PROJECT_DIR=$1

# Verify input.

if [ -z ${SENZING_PROJECT_DIR} ]; then
    echo "${USAGE}"
    echo "ERROR: Missing project-dir."
    exit 1
fi

# Verify environment. curl, docker, python3

if [ ! -n "$(command -v curl)" ]; then
    echo "ERROR: curl is required."
    echo "See https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-curl.md"
    exit 1
fi

if [ ! -n "$(command -v docker)" ]; then
    echo "ERROR: docker is required."
    echo "See https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-docker.md"
    exit 1
fi

if [ -n "$(command -v python3)" ]; then
    PYTHON3_INSTALLED=1
else
    echo "WARNING: python3 is not installed."
    echo "See https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-python-3.md"
fi

# Configuration via environment variables.

SENZING_ENVIRONMENT_SUBCOMMAND=${SENZING_ENVIRONMENT_SUBCOMMAND:-"add-docker-support-macos"}

# Synthesize variables.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SENZING_PROJECT_DIR_REALPATH=$(find_realpath ${SENZING_PROJECT_DIR})

SENZING_DATA_DIR=${SENZING_PROJECT_DIR_REALPATH}/data
SENZING_DOCKER_BIN_DIR=${SENZING_PROJECT_DIR_REALPATH}/docker-bin
SENZING_ETC_DIR=${SENZING_PROJECT_DIR_REALPATH}/docker-etc
SENZING_G2_DIR=${SENZING_PROJECT_DIR_REALPATH}/g2
SENZING_PROJECT_NAME=$(basename "${SENZING_PROJECT_DIR_REALPATH}")
SENZING_VAR_DIR=${SENZING_PROJECT_DIR_REALPATH}/var

# Give user information.

echo "Project location: ${SENZING_PROJECT_DIR_REALPATH}"
echo ""

# DEBUG: Print exports of environment variables.
# echo "export SENZING_DATA_DIR=${SENZING_DATA_DIR}"
# echo "export SENZING_DOCKER_BIN_DIR=${SENZING_DOCKER_BIN_DIR}"
# echo "export SENZING_ETC_DIR=${SENZING_ETC_DIR}"
# echo "export SENZING_G2_DIR=${SENZING_G2_DIR}"
# echo "export SENZING_PROJECT_DIR_REALPATH=${SENZING_PROJECT_DIR_REALPATH}"
# echo "export SENZING_PROJECT_NAME=${SENZING_PROJECT_NAME}"
# echo "export SENZING_VAR_DIR=${SENZING_VAR_DIR}"

# Prompt user.

read -t 30 -p "Would you like to detect and install updates?  [y|N] " UPDATES_RESPONSE
case ${UPDATES_RESPONSE} in
    [Yy]* ) PERFORM_UPDATES=1;;
    * ) ;;
esac
echo ""

# Tricky code.  Simply prompting user for sudo access.

echo "To run Docker, you may be prompted for your sudo password."
sudo ls > /dev/null 2>&1

# If requested, perform updates.

if [ ! -z ${PERFORM_UPDATES} ]; then
    perform_docker_pulls
fi

# If the project directory doesn't exist, create it.

if [ ! -d ${SENZING_PROJECT_DIR} ]; then
    mkdir -p ${SENZING_PROJECT_DIR}
    perform_docker_pulls
fi

# If new project or update requested, install/update Senzing.

if [[ ( ! -e ${SENZING_G2_DIR}/g2BuildVersion.json ) \
   || ( ! -z ${PERFORM_UPDATES} ) \
   ]]; then

    TIMESTAMP=$(date +%s)

    # If symbolic links exist, move them.
    # If successful, they will be removed later.

    if [ -e ${SENZING_G2_DIR} ]; then
        mv ${SENZING_G2_DIR} ${SENZING_G2_DIR}-bak-${TIMESTAMP}
    fi

    if [ -e ${SENZING_DATA_DIR} ]; then
        mv ${SENZING_DATA_DIR} ${SENZING_DATA_DIR}-bak-${TIMESTAMP}
    fi

    # Download Senzing binaries.

    sudo docker run \
      --interactive \
      --name ${SENZING_PROJECT_NAME}-yum \
      --rm \
      --tty \
      --volume ${SENZING_PROJECT_DIR_REALPATH}:/opt/senzing \
      senzing/yum:latest

# DEBUG: local install.
#    sudo docker run \
#        --env SENZING_ACCEPT_EULA=I_ACCEPT_THE_SENZING_EULA \
#        --name ${SENZING_PROJECT_NAME}-yum \
#        --rm \
#        --volume ${SENZING_PROJECT_DIR_REALPATH}:/opt/senzing \
#        --volume ~/Downloads:/data \
#        senzing/yum -y localinstall /data/senzingapi-1.15.0-20106.x86_64.rpm /data/senzingdata-v1-1.0.0-19287.x86_64.rpm

    sudo chown -R $(id -u):$(id -g) ${SENZING_PROJECT_DIR_REALPATH}

    # Create symbolic links to timestamped directories.
    # Tricky code: Accounting for a failed/cancelled YUM install.

    pushd ${SENZING_PROJECT_DIR_REALPATH}

    if [ -e ${SENZING_G2_DIR} ]; then
        mv g2 g2.${TIMESTAMP}
        ln -s g2.${TIMESTAMP} g2
        rm ${SENZING_G2_DIR}-bak-${TIMESTAMP}
    else
        mv ${SENZING_G2_DIR}-bak-${TIMESTAMP} ${SENZING_G2_DIR}
    fi

    if [ -e ${SENZING_DATA_DIR} ]; then
        mv data data-backup
        mv data-backup/1.0.0 data.${TIMESTAMP}
        rmdir data-backup
        ln -s data.${TIMESTAMP} data
        rm ${SENZING_DATA_DIR}-bak-${TIMESTAMP}
    else
        mv ${SENZING_DATA_DIR}-bak-${TIMESTAMP} ${SENZING_DATA_DIR}
    fi

    popd > /dev/null 2>&1
fi

# If needed, populate docker-bin directory.

DOCKER_ENVIRONMENT_VARS_FILENAME=${SENZING_DOCKER_BIN_DIR}/docker-environment-vars.sh

if [[ ( ! -e ${DOCKER_ENVIRONMENT_VARS_FILENAME} ) \
   && ( ! -z ${PYTHON3_INSTALLED} ) \
   ]]; then

    # If needed, add senzing-environment.py.

    SENZING_ENVIRONMENT_FILENAME=${SENZING_PROJECT_DIR_REALPATH}/senzing-environment.py

    if [[ ( ! -e ${SENZING_ENVIRONMENT_FILENAME} ) ]]; then

        curl -X GET \
            --output ${SENZING_ENVIRONMENT_FILENAME} \
            https://raw.githubusercontent.com/Senzing/senzing-environment/master/senzing-environment.py

        chmod +x ${SENZING_ENVIRONMENT_FILENAME}

    fi

    # Populate .../docker-bin directory.

    if [ ! -d ${SENZING_DOCKER_BIN_DIR} ]; then
        mkdir -p ${SENZING_DOCKER_BIN_DIR}
    fi

    ${SENZING_ENVIRONMENT_FILENAME} ${SENZING_ENVIRONMENT_SUBCOMMAND} --project-dir ${SENZING_PROJECT_DIR} > /dev/null 2>&1

    mv ${SENZING_ENVIRONMENT_FILENAME} ${SENZING_DOCKER_BIN_DIR}

fi

# If needed, initialize etc and var directories.

if [ ! -e ${SENZING_ETC_DIR} ]; then

    sudo docker run \
        --name ${SENZING_PROJECT_NAME}-init-container \
        --rm \
        --user 0 \
        --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
        --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
        --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
        --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
        senzing/init-container:latest > /dev/null 2>&1

    sudo chown -R $(id -u):$(id -g) ${SENZING_PROJECT_DIR_REALPATH}

fi

# If requested, update Senzing database schema.

if [[ ( ! -z ${PERFORM_UPDATES} ) ]]; then

    echo "Updating Senzing database schema."

    sudo docker run \
        --name ${SENZING_PROJECT_NAME}-update-database \
        --rm \
        --user $(id -u):$(id -g) \
        --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
        --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
        --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
        --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
        senzing/senzing-debug:latest \
            /opt/senzing/g2/bin/g2dbupgrade \
                -c /etc/opt/senzing/G2Module.ini \
                -a \
            > /dev/null 2>&1

fi

# If requested, update Senzing configuration.

if [[ ( ! -z ${PERFORM_UPDATES} ) ]]; then

    echo "Updating Senzing configuration."

    for FULL_PATHNAME in ${SENZING_G2_DIR}/resources/config/*; do
        FILENAME=$(basename ${FULL_PATHNAME})

        echo ".. Verifying ${FILENAME}"

        sudo docker run \
            --name ${SENZING_PROJECT_NAME}-update-config \
            --rm \
            --user $(id -u):$(id -g) \
            --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
            --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
            --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
            --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
            senzing/senzing-debug:latest \
                /opt/senzing/g2/python/G2ConfigTool.py \
                    -c /etc/opt/senzing/G2Module.ini \
                    -f /opt/senzing/g2/resources/config/${FILENAME} \
                > /dev/null 2>&1

        RETURN_CODE=$?

        echo ".... return code: ${RETURN_CODE}"
    done

fi

# Run web-app.

echo "${SENZING_PROJECT_NAME}-quickstart running on http://localhost:8251"
echo "To exit, CTRL-C"

sudo docker run \
    --name ${SENZING_PROJECT_NAME}-quickstart \
    --publish 8251:8251 \
    --rm \
    --user $(id -u):$(id -g) \
    --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
    --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
    --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
    --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
    senzing/web-app-demo:latest > /dev/null 2>&1

echo "Done."
