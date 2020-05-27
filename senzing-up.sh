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
    echo "Pulling Docker images."

    docker pull senzing/g2loader:latest > /dev/null 2>&1
    docker pull senzing/init-container:latest > /dev/null 2>&1
    docker pull senzing/senzing-debug:latest > /dev/null 2>&1
    docker pull senzing/web-app-demo:latest > /dev/null 2>&1
    docker pull senzing/yum:latest > /dev/null 2>&1
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
TRUTH_SET_1_DATA_SOURCE_NAME=${TRUTH_SET_1_DATA_SOURCE_NAME:-"customer"}
TRUTH_SET_2_DATA_SOURCE_NAME=${TRUTH_SET_2_DATA_SOURCE_NAME:-"watchlist"}
WEB_APP_PORT=8251

# Synthesize variables.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SENZING_PROJECT_DIR_REALPATH=$(find_realpath ${SENZING_PROJECT_DIR})

SENZING_DATA_DIR=${SENZING_PROJECT_DIR_REALPATH}/data
SENZING_DOCKER_BIN_DIR=${SENZING_PROJECT_DIR_REALPATH}/docker-bin
SENZING_ETC_DIR=${SENZING_PROJECT_DIR_REALPATH}/docker-etc
SENZING_G2_DIR=${SENZING_PROJECT_DIR_REALPATH}/g2
SENZING_PROJECT_NAME=$(basename "${SENZING_PROJECT_DIR_REALPATH}")
SENZING_VAR_DIR=${SENZING_PROJECT_DIR_REALPATH}/var
HORIZONTAL_RULE="=============================================================================="

# DEBUG: For debugging: print exports of environment variables.
# echo "export SENZING_DATA_DIR=${SENZING_DATA_DIR}"
# echo "export SENZING_DOCKER_BIN_DIR=${SENZING_DOCKER_BIN_DIR}"
# echo "export SENZING_ETC_DIR=${SENZING_ETC_DIR}"
# echo "export SENZING_G2_DIR=${SENZING_G2_DIR}"
# echo "export SENZING_PROJECT_DIR_REALPATH=${SENZING_PROJECT_DIR_REALPATH}"
# echo "export SENZING_PROJECT_NAME=${SENZING_PROJECT_NAME}"
# echo "export SENZING_VAR_DIR=${SENZING_VAR_DIR}"

# Tricky code.  Simply prompting user for sudo access.

echo "To run Docker, you may be prompted for your sudo password."
sudo ls > /dev/null 2>&1

# If the project directory doesn't exist, create it.

if [ ! -d ${SENZING_PROJECT_DIR} ]; then
    mkdir -p ${SENZING_PROJECT_DIR}
    FIRST_TIME_INSTALL=1
    perform_docker_pulls

# If directory exists, ask if an update is desired.
# If someone is doing a demo, they shouldn't have to wait for an update.

else

    read -t 30 -p "Would you like to detect and install updates?  [y|N] " UPDATES_RESPONSE
    case ${UPDATES_RESPONSE} in
        [Yy]* ) PERFORM_UPDATES=1;;
        * ) ;;
    esac
    echo ""
fi

# If requested, perform updates.

if [ ! -z ${PERFORM_UPDATES} ]; then
    perform_docker_pulls
fi

# FIXME: Compoare publicly available Senzing version with installed version.

# If new project or update requested, install/update Senzing.

if [[ ( ! -e ${SENZING_G2_DIR}/g2BuildVersion.json ) \
   || ( ! -z ${PERFORM_UPDATES} ) \
   ]]; then

    echo "Installing Senzing."

    # FIXME: Determine version of Senzing being installed as directory suffix.

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

#    sudo docker run \
#      --env SENZING_ACCEPT_EULA=${SENZING_ACCEPT_EULA} \
#      --interactive \
#      --name ${SENZING_PROJECT_NAME}-yum \
#      --rm \
#      --tty \
#      --volume ${SENZING_PROJECT_DIR_REALPATH}:/opt/senzing \
#      senzing/yum:latest

# DEBUG: local install.
    sudo docker run \
        --env SENZING_ACCEPT_EULA=I_ACCEPT_THE_SENZING_EULA \
        --name ${SENZING_PROJECT_NAME}-yum \
        --rm \
        --volume ${SENZING_PROJECT_DIR_REALPATH}:/opt/senzing \
        --volume ~/Downloads:/data \
        senzing/yum -y localinstall /data/senzingapi-1.15.0-20106.x86_64.rpm /data/senzingdata-v1-1.0.0-19287.x86_64.rpm

    sudo chown -R $(id -u):$(id -g) ${SENZING_PROJECT_DIR_REALPATH}

    # Create symbolic links to timestamped directories.
    # Tricky code: Accounting for a failed/cancelled YUM install.

    pushd ${SENZING_PROJECT_DIR_REALPATH}

    if [ -e ${SENZING_G2_DIR} ]; then
        mv g2 g2.${TIMESTAMP}
        ln -s g2.${TIMESTAMP} g2
        rm ${SENZING_G2_DIR}-bak-${TIMESTAMP} > /dev/null 2>&1

    else
        mv ${SENZING_G2_DIR}-bak-${TIMESTAMP} ${SENZING_G2_DIR}
    fi

    if [ -e ${SENZING_DATA_DIR} ]; then
        mv data data-backup
        mv data-backup/1.0.0 data.${TIMESTAMP}
        rmdir data-backup
        ln -s data.${TIMESTAMP} data
        rm ${SENZING_DATA_DIR}-bak-${TIMESTAMP} > /dev/null 2>&1
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

    # Remove obsolete GTC files.

    rm /opt/senzing/g2/resources/config/g2core-config-upgrade-1.9-to-1.10.gtc

    # Apply all G2C files in alphabetical order.

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

# Load Senzing Model with sample data.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) ]]; then
    echo "Loading sample data."

    # Download sample data files.

    curl -X GET \
        --output ${SENZING_VAR_DIR}/truthset-person-v1-set1.csv \
        https://public-read-access.s3.amazonaws.com/TestDataSets/SenzingTruthSet/truthset-person-v1-set1.csv \
        > /dev/null 2>&1


    curl -X GET \
        --output ${SENZING_VAR_DIR}/truthset-person-v1-set2.csv \
        https://public-read-access.s3.amazonaws.com/TestDataSets/SenzingTruthSet/truthset-person-v1-set2.csv \
        > /dev/null 2>&1

    # Create file:  sample-data-project.csv

    cat <<EOT > ${SENZING_VAR_DIR}/sample-data-project.csv
DATA_SOURCE,FILE_FORMAT,FILE_NAME
${TRUTH_SET_1_DATA_SOURCE_NAME},CSV,/var/opt/senzing/truthset-person-v1-set1.csv
${TRUTH_SET_2_DATA_SOURCE_NAME},CSV,/var/opt/senzing/truthset-person-v1-set2.csv
EOT

    # Create file:  sample-data-project.ini

    cat <<EOT > ${SENZING_VAR_DIR}/sample-data-project.ini
[g2]
G2Connection=sqlite3://na:na@/var/opt/senzing/sqlite/G2C.db
iniPath=/etc/opt/senzing/G2Module.ini
collapsedTableSchema=Y
evalQueueProcessing=1

[project]
projectFileName=/var/opt/senzing/sample-data-project.csv

[transport]
numThreads=4

[report]
sqlCommitSize=1000
reportCategoryLimit=1000
EOT

    # Invoke G2Loader.py via Docker container to load files into Senzing Model.

    sudo docker run \
        --name ${SENZING_PROJECT_NAME}-g2loader \
        --rm \
        --user $(id -u):$(id -g) \
        --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
        --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
        --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
        --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
        senzing/g2loader:latest \
            -c /var/opt/senzing/sample-data-project.ini \
            -p /var/opt/senzing/sample-data-project.csv \
        > /dev/null 2>&1

fi

# Give user information before Docker container runs.

echo ""
echo "${HORIZONTAL_RULE}"
echo "${HORIZONTAL_RULE:0:2} Project location: ${SENZING_PROJECT_DIR_REALPATH}"
echo "${HORIZONTAL_RULE:0:2} ${SENZING_PROJECT_NAME}-quickstart running on http://localhost:${WEB_APP_PORT}"

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) ]]; then
    echo "${HORIZONTAL_RULE:0:2} For tour of sample data, see https://senzing.zendesk.com/hc/en-us/articles/360047940434-Synthetic-Truth-Sets"
fi

echo "${HORIZONTAL_RULE}"
echo ""
echo "To exit, CTRL-C"
echo ""

# Run web-app Docker container.

sudo docker run \
    --name ${SENZING_PROJECT_NAME}-quickstart \
    --publish ${WEB_APP_PORT}:8251 \
    --rm \
    --user $(id -u):$(id -g) \
    --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
    --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
    --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
    --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
    senzing/web-app-demo:latest > /dev/null 2>&1

echo "Done."
