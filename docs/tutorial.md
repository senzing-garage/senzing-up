# senzing-up tutorial

The following demonstrations show how to use `senzing-up` projects.

## Prerequisites for Tutorial

:thinking: The following tasks need to be complete before proceeding.
These are "one-time tasks" which may already have been completed.

1. The following software programs need to be installed:
    1. [docker](https://github.com/Senzing/knowledge-base/blob/main/HOWTO/install-docker.md)
    1. [senzing-up](https://github.com/Senzing/senzing-up)

## Demonstrations

1. [Demonstration 1](#demonstration-1) - Senzing Entity Server Web app.
   This is the "default" demonstration launched by `senzing-up.sh`.
1. [Demonstration 2](#demonstration-2) - Exploratory Data Analysis.
1. [Demonstration 3](#demonstration-3) - Swagger API explorer.
1. [Demonstration 4](#demonstration-4) - Jupyter notebooks.
1. [Demonstration 5](#demonstration-5) - View database.
1. [Demonstration 6](#demonstration-6) - Load CSV file into Senzing Engine using G2Loader.

## Demonstration 1

Bring up the Senzing Entity Server Web app.

1. :pencil2: Identify directory created by `senzing-up.py`.
   Example:

    ```console
    export SENZING_UP_DIR=~/senzing-up-demonstration
    ```

1. Bring up demonstration.
   Example

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-webapp-demo.sh up
    ```

1. Visit Senzing Entity Search Webapp at
   [localhost:8251](http://localhost:8251)

1. Bring down demonstration.
   Example:

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-webapp-demo.sh down
    ```

## Demonstration 2

Exploratory Data Analysis.

1. :pencil2: Identify directory created by `senzing-up.py`.
   Example:

    ```console
    export SENZING_UP_DIR=~/senzing-up-demonstration
    ```

1. Bring up demonstration.
   Example

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-console.sh up
    ```

1. Visit
   [Exploratory Data Analysis (EDA)](https://senzing.zendesk.com/hc/en-us/sections/360009388534-Exploratory-Data-Analysis-EDA-)
   tutorial.

1. To bring down demonstration, simply type "exit" at the command prompt.
   Example:

    ```console
    exit
    ```

## Demonstration 3

Swagger

1. :pencil2: Identify directory created by `senzing-up.py`.
   Example:

    ```console
    export SENZING_UP_DIR=~/senzing-up-demonstration
    ```

1. Bring up Senzing API Server.
   Example

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-api-server.sh up
    ```

1. Bring up Swagger User Interface.
   Example

    ```console
    ${SENZING_UP_DIR}/docker-bin/swagger-ui.sh up
    ```

1. Visit
   [localhost:9180](http://localhost:9180)

1. Bring down demonstration.
   Example:

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-api-server.sh down
    ${SENZING_UP_DIR}/docker-bin/swagger-ui.sh down
    ```

## Demonstration 4

Jupyter notebooks

1. :pencil2: Identify directory created by `senzing-up.py`.
   Example:

    ```console
    export SENZING_UP_DIR=~/senzing-up-demonstration
    ```

1. Bring up Jupyter notebooks.
   Example

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-jupyter.sh up
    ```

1. Visit
   [localhost:9178](http://localhost:9178)

1. Bring down demonstration.
   Example:

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-jupyter.sh down
    ```

## Demonstration 5

View database.

1. :pencil2: Identify directory created by `senzing-up.py`.
   Example:

    ```console
    export SENZING_UP_DIR=~/senzing-up-demonstration
    ```

1. Bring up Jupyter notebooks.
   Example

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-sqlite-web.sh up
    ```

1. Visit
   [localhost:9174](http://localhost:9174)

1. Bring down demonstration.
   Example:

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-sqlite-web.sh down
    ```

## Demonstration 6

Load CSV file into Senzing Engine using G2Loader.

1. :pencil2: Identify directory created by `senzing-up.py`.
   Example:

    ```console
    export SENZING_UP_DIR=~/senzing-up-demonstration
    ```

1. :pencil2: Copy your `csv` file to `${SENZING_UP_DIR}/var` so that it can be seen inside the docker container.
   Example:

    ```console
    cp /path/to/my.csv ${SENZING_UP_DIR}/var/my.csv
    ```

1. Make sure docker network is up.
   Example:

    ```console
    sudo docker network create senzing-up
    ```

1. Bring up the Senzing console docker image.
   Example:

    ```console
    ${SENZING_UP_DIR}/docker-bin/senzing-console.sh
    ```

1. In the Senzing console, verify your file is there.
   Example:

    ```console
    ls -la /var/opt/senzing
    ```

1. In the Senzing console, use `G2Loader.py` to load the data.
   Example:

    ```console
    G2Loader.py -f /var/opt/senzing/my.csv/?data_source=TEST,file_format=CSV
    ```

1. For more information on `G2Loader.py`, see
   [Getting Started](https://senzing.zendesk.com/hc/en-us/articles/115004450368-Getting-Started).
