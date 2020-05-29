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

# Verify input.

if [ -z ${SENZING_PROJECT_DIR} ]; then
    echo "${USAGE}"
    echo "ERROR: Missing project-dir."
    exit 1
fi

# Verify environment. curl, docker, python3.

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

# Determine if Docker is running.

sudo -p "To run Docker, please enter sudo password:  " docker info >> /dev/null 2>&1
DOCKER_RETURN_CODE=$?
if [  "${DOCKER_RETURN_CODE}" != "0" ]; then
    echo "ERROR: Docker is not running."
    echo "Please start Docker."
    exit 1
fi

# Configuration via environment variables.

SENZING_ENVIRONMENT_SUBCOMMAND=${SENZING_ENVIRONMENT_SUBCOMMAND:-"add-docker-support-macos"}
TRUTH_SET_1_DATA_SOURCE_NAME=${SENZING_TRUTH_SET_1_DATA_SOURCE_NAME:-"customer"}
TRUTH_SET_2_DATA_SOURCE_NAME=${SENZING_TRUTH_SET_2_DATA_SOURCE_NAME:-"watchlist"}
WEB_APP_PORT=${SENZING_WEB_APP_PORT:-"8251"}

# Synthesize variables.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
SENZING_PROJECT_DIR_REALPATH=$(find_realpath ${SENZING_PROJECT_DIR})

SENZING_DATA_DIR=${SENZING_PROJECT_DIR_REALPATH}/data
SENZING_DOCKER_BIN_DIR=${SENZING_PROJECT_DIR_REALPATH}/docker-bin
SENZING_ETC_DIR=${SENZING_PROJECT_DIR_REALPATH}/docker-etc
SENZING_G2_DIR=${SENZING_PROJECT_DIR_REALPATH}/g2
SENZING_HISTORY_FILE=${SENZING_PROJECT_DIR_REALPATH}/.senzing/history.log
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

# If the project directory doesn't exist, create it.

if [ ! -d ${SENZING_PROJECT_DIR} ]; then
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

# If first time or requested, prompt for EULA acceptance.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) \
   || ( ! -z ${PERFORM_UPDATES} ) \
   ]]; then

    echo "The Senzing end user license agreement can be found at https://senzing.com/end-user-license-agreement/"
    echo ""
    read -p "Do you accept the license terms and conditions?  [y/N] " EULA_RESPONSE
    case ${EULA_RESPONSE} in
        [Yy]* ) SENZING_ACCEPT_EULA=I_ACCEPT_THE_SENZING_EULA;;
        * ) echo "EULA not accepted. Must enter 'Y' to accept EULA."
            exit 1;;
    esac
fi

# First time install instructions.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) ]]; then
    mkdir -p ${SENZING_PROJECT_DIR}/.senzing >> ${SENZING_HISTORY_FILE} 2>&1
fi

# Make entry in history log.

echo "" >> ${SENZING_HISTORY_FILE} 2>&1
echo "${HORIZONTAL_RULE}" >> ${SENZING_HISTORY_FILE} 2>&1
echo "${HORIZONTAL_RULE:0:2} Start time: $(date)" >> ${SENZING_HISTORY_FILE} 2>&1
echo "${HORIZONTAL_RULE}" >> ${SENZING_HISTORY_FILE} 2>&1
echo "" >> ${SENZING_HISTORY_FILE} 2>&1

echo "To view log, run: tail -f ${SENZING_HISTORY_FILE}"

# If first time or update, pull docker images.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) \
   || ( ! -z ${PERFORM_UPDATES} ) \
   ]]; then

    echo "Pulling Docker images."

    sudo docker pull senzing/g2loader:latest >> ${SENZING_HISTORY_FILE} 2>&1
    echo -ne 'Pulling ...\r'
    sudo docker pull senzing/init-container:latest >> ${SENZING_HISTORY_FILE} 2>&1
    echo -ne 'Pulling ......\r'
    sudo docker pull senzing/senzing-debug:latest >> ${SENZING_HISTORY_FILE} 2>&1
    echo -ne 'Pulling .........\r'
    sudo docker pull senzing/web-app-demo:latest >> ${SENZING_HISTORY_FILE} 2>&1
    echo -ne 'Pulling ............\r'
    sudo docker pull senzing/yum:latest >> ${SENZING_HISTORY_FILE} 2>&1
    echo -ne 'Pulling ...............\r'

fi

# If new project or update requested, install/update Senzing.

if [[ ( ! -e ${SENZING_G2_DIR}/g2BuildVersion.json ) \
   || ( ! -e ${SENZING_DATA_DIR}/terms.ibm ) \
   || ( ! -z ${PERFORM_UPDATES} ) \
   ]]; then

    if [[ ( ! -z ${PERFORM_UPDATES} ) ]]; then
        echo "Determining if a new version of Senzing exists."
    fi

    # Determine version of senzingapi on public repository.

    sudo docker run \
      --rm \
      senzing/yum list senzingapi > ${SENZING_PROJECT_DIR}/yum-list-senzingapi.txt

    SENZING_G2_CURRENT_VERSION=$(grep senzingapi ${SENZING_PROJECT_DIR}/yum-list-senzingapi.txt | awk '{print $2}' | awk -F \- {'print $1'})
    SENZING_G2_DIR_CURRENT=${SENZING_G2_DIR}-${SENZING_G2_CURRENT_VERSION}
    rm ${SENZING_PROJECT_DIR}/yum-list-senzingapi.txt >> ${SENZING_HISTORY_FILE} 2>&1

    # Determine version of senzingdata on public repository.

    sudo docker run \
      --rm \
      senzing/yum list senzingdata-v1 > ${SENZING_PROJECT_DIR}/yum-list-senzingdata.txt

    SENZING_DATA_CURRENT_VERSION=$(grep senzingdata ${SENZING_PROJECT_DIR}/yum-list-senzingdata.txt | awk '{print $2}' | awk -F \- {'print $1'})
    SENZING_DATA_DIR_CURRENT=${SENZING_DATA_DIR}-${SENZING_DATA_CURRENT_VERSION}
    rm ${SENZING_PROJECT_DIR}/yum-list-senzingdata.txt >> ${SENZING_HISTORY_FILE} 2>&1

    # If new version available, install it.

    if [[ ( ! -e ${SENZING_G2_DIR_CURRENT} ) ]]; then

        echo "Installing SenzingApi ${SENZING_G2_CURRENT_VERSION}"
        echo -ne '...this will take time. Depending on network speeds, up to and beyond 15 minutes.\r'

        # If symbolic links exist, move them.
        # If successful, they will be removed later.
        # If unsuccessful, they will be restored.

        TIMESTAMP=$(date +%s)

        if [ -e ${SENZING_G2_DIR} ]; then
            mv ${SENZING_G2_DIR} ${SENZING_G2_DIR}-bak-${TIMESTAMP} >> ${SENZING_HISTORY_FILE} 2>&1
        fi

        if [ -e ${SENZING_DATA_DIR} ]; then
            mv ${SENZING_DATA_DIR} ${SENZING_DATA_DIR}-bak-${TIMESTAMP} >> ${SENZING_HISTORY_FILE} 2>&1
        fi

        # Download Senzing binaries.

        sudo docker run \
          --env SENZING_ACCEPT_EULA=${SENZING_ACCEPT_EULA} \
          --rm \
          --volume ${SENZING_PROJECT_DIR_REALPATH}:/opt/senzing \
          senzing/yum:latest \
          >> ${SENZING_HISTORY_FILE} 2>&1

        # DEBUG: local install.

#        sudo docker run \
#            --env SENZING_ACCEPT_EULA=${SENZING_ACCEPT_EULA} \
#            --rm \
#            --volume ${SENZING_PROJECT_DIR_REALPATH}:/opt/senzing \
#            --volume ~/Downloads:/data \
#            senzing/yum -y localinstall /data/senzingapi-1.15.0-20106.x86_64.rpm /data/senzingdata-v1-1.0.0-19287.x86_64.rpm \
#         >> ${SENZING_HISTORY_FILE} 2>&1

        sudo chown -R $(id -u):$(id -g) ${SENZING_PROJECT_DIR_REALPATH} >> ${SENZING_HISTORY_FILE} 2>&1

        # Create symbolic links to versioned directories.
        # Tricky code: Also accounting for a failed/cancelled YUM install.

        pushd ${SENZING_PROJECT_DIR_REALPATH} >> ${SENZING_HISTORY_FILE} 2>&1

        # Move "g2" to "g2-M.m.P" directory and make "g2" symlink.

        if [ -e ${SENZING_G2_DIR} ]; then
            mv g2 g2-${SENZING_G2_CURRENT_VERSION} >> ${SENZING_HISTORY_FILE} 2>&1
            ln -s g2-${SENZING_G2_CURRENT_VERSION} g2 >> ${SENZING_HISTORY_FILE} 2>&1
            rm ${SENZING_G2_DIR}-bak-${TIMESTAMP} >> ${SENZING_HISTORY_FILE} 2>&1


        else
            mv ${SENZING_G2_DIR}-bak-${TIMESTAMP} ${SENZING_G2_DIR} >> ${SENZING_HISTORY_FILE} 2>&1
        fi

        # Move "data" to "data-M.m.P" directory, remove the version subdirectory, make "data" symlink.

        if [[ ( ! -e ${SENZING_DATA_DIR_CURRENT} ) ]]; then
            mv data data-backup >> ${SENZING_HISTORY_FILE} 2>&1
            mv data-backup/1.0.0 data-${SENZING_DATA_CURRENT_VERSION} >> ${SENZING_HISTORY_FILE} 2>&1
            rmdir data-backup >> ${SENZING_HISTORY_FILE} 2>&1
            ln -s data-${SENZING_DATA_CURRENT_VERSION} data >> ${SENZING_HISTORY_FILE} 2>&1
            rm ${SENZING_DATA_DIR}-bak-${TIMESTAMP} >> ${SENZING_HISTORY_FILE} 2>&1

        else
            rm -rf ${SENZING_DATA_DIR} >> ${SENZING_HISTORY_FILE} 2>&1
            mv ${SENZING_DATA_DIR}-bak-${TIMESTAMP} ${SENZING_DATA_DIR} >> ${SENZING_HISTORY_FILE} 2>&1
        fi

        popd >> ${SENZING_HISTORY_FILE} 2>&1


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
            https://raw.githubusercontent.com/Senzing/senzing-environment/master/senzing-environment.py \
            >> ${SENZING_HISTORY_FILE} 2>&1

        chmod +x ${SENZING_ENVIRONMENT_FILENAME} >> ${SENZING_HISTORY_FILE} 2>&1

    fi

    # Populate docker-bin and docker-etc directories.

    if [ ! -z ${PYTHON3_INSTALLED} ]; then
        ${SENZING_ENVIRONMENT_FILENAME} ${SENZING_ENVIRONMENT_SUBCOMMAND} --project-dir ${SENZING_PROJECT_DIR} >> ${SENZING_HISTORY_FILE} 2>&1
    fi

    if [ ! -d ${SENZING_DOCKER_BIN_DIR} ]; then
        mkdir -p ${SENZING_DOCKER_BIN_DIR} >> ${SENZING_HISTORY_FILE} 2>&1
    fi

    mv ${SENZING_ENVIRONMENT_FILENAME} ${SENZING_DOCKER_BIN_DIR} >> ${SENZING_HISTORY_FILE} 2>&1

fi

# If needed, initialize etc and var directories.

if [ ! -e ${SENZING_ETC_DIR} ]; then

    echo "Creating ${SENZING_ETC_DIR}"
    echo "Initializing Senzing configuration."

    sudo docker run \
        --rm \
        --user 0 \
        --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
        --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
        --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
        --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
        senzing/init-container:latest >> ${SENZING_HISTORY_FILE} 2>&1

    sudo chown -R $(id -u):$(id -g) ${SENZING_PROJECT_DIR_REALPATH} >> ${SENZING_HISTORY_FILE} 2>&1

fi

# If requested, update Senzing database schema.

if [[ ( ! -z ${PERFORM_UPDATES} ) ]]; then

    echo "Updating Senzing database schema."

    sudo docker run \
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
            >> ${SENZING_HISTORY_FILE} 2>&1

fi

# If requested, update Senzing configuration.

if [[ ( ! -z ${PERFORM_UPDATES} ) ]]; then

    echo "Updating Senzing configuration."

    # Remove obsolete GTC files.

    sudo rm --force ${SENZING_G2_DIR}/resources/config/g2core-config-upgrade-1.9-to-1.10.gtc >> ${SENZING_HISTORY_FILE} 2>&1

    # Apply all G2C files in alphabetical order.

    for FULL_PATHNAME in ${SENZING_G2_DIR}/resources/config/*; do
        FILENAME=$(basename ${FULL_PATHNAME})

        echo ".. Verifying ${FILENAME}" >> ${SENZING_HISTORY_FILE} 2>&1

        sudo docker run \
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
                >> ${SENZING_HISTORY_FILE} 2>&1

        RETURN_CODE=$?

        echo ".... return code: ${RETURN_CODE}" >> ${SENZING_HISTORY_FILE} 2>&1
    done

fi

# Load Senzing Model with sample data.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) ]]; then
    echo "Loading sample data."

    # Download sample data files.

    curl -X GET \
        --output ${SENZING_VAR_DIR}/truthset-person-v1-set1.csv \
        https://public-read-access.s3.amazonaws.com/TestDataSets/SenzingTruthSet/truthset-person-v1-set1.csv \
        >> ${SENZING_HISTORY_FILE} 2>&1


    curl -X GET \
        --output ${SENZING_VAR_DIR}/truthset-person-v1-set2.csv \
        https://public-read-access.s3.amazonaws.com/TestDataSets/SenzingTruthSet/truthset-person-v1-set2.csv \
        >> ${SENZING_HISTORY_FILE} 2>&1

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
        --rm \
        --user $(id -u):$(id -g) \
        --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
        --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
        --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
        --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
        senzing/g2loader:latest \
            -c /var/opt/senzing/sample-data-project.ini \
            -p /var/opt/senzing/sample-data-project.csv \
        >> ${SENZING_HISTORY_FILE} 2>&1

fi

# Give user information before Docker container runs.

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) ]]; then
    echo "Installation is complete."
    echo "Installation is complete." >> ${SENZING_HISTORY_FILE} 2>&1
elif [[ ( ! -z ${PERFORM_UPDATES} ) ]]; then
    echo "Update is complete."
    echo "Update is complete." >> ${SENZING_HISTORY_FILE} 2>&1
fi

# Make entry in history log.

echo "" >> ${SENZING_HISTORY_FILE} 2>&1
echo "${HORIZONTAL_RULE}" >> ${SENZING_HISTORY_FILE} 2>&1
echo "${HORIZONTAL_RULE:0:2} Stop time: $(date)" >> ${SENZING_HISTORY_FILE} 2>&1
echo "${HORIZONTAL_RULE}" >> ${SENZING_HISTORY_FILE} 2>&1
echo "" >> ${SENZING_HISTORY_FILE} 2>&1

# Print epilog in terminal.

echo ""
echo "${HORIZONTAL_RULE}"
echo "${HORIZONTAL_RULE:0:2} View: http://localhost:${WEB_APP_PORT}"

if [[ ( ! -z ${FIRST_TIME_INSTALL} ) ]]; then
    echo "${HORIZONTAL_RULE:0:2} For tour of sample data, see https://senzing.zendesk.com/hc/en-us/articles/360047940434-Synthetic-Truth-Sets"
fi

echo "${HORIZONTAL_RULE:0:2} Project location: ${SENZING_PROJECT_DIR_REALPATH}"
echo "${HORIZONTAL_RULE}"
echo ""
echo "The senzing/web-app-demo Docker container is running in this window."
echo "To stop the container, enter CTRL-C"
echo ""

# Run web-app Docker container.

sudo docker run \
    --publish ${WEB_APP_PORT}:8251 \
    --rm \
    --user $(id -u):$(id -g) \
    --volume ${SENZING_DATA_DIR}:/opt/senzing/data \
    --volume ${SENZING_ETC_DIR}:/etc/opt/senzing \
    --volume ${SENZING_G2_DIR}:/opt/senzing/g2 \
    --volume ${SENZING_VAR_DIR}:/var/opt/senzing \
    senzing/web-app-demo:latest \
    >> ${SENZING_HISTORY_FILE} 2>&1

echo "Done."
