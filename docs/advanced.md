# senzing-up advanced

## Multi-tenancy

### First tenant

1. Use `senzing-up.sh` to create the first tenant.
   Example:

    ```console
    ~/senzing-up.sh ~/senzing-up-demonstration-1
    ```

### Next tenants

To create additional tenants, it's not necessary to run `senzing-up.sh` again (although it will work).
Copying and modifying will work.

1. Copy the directory for Tenant #1 into a new directory
   Example:

    ```console
    cp --recursive ~/senzing-up-demonstration-1 ~/senzing-up-demonstration-N
    ```

1. Specify unique ports for Tenant #N's docker containers.
   To do this, edit `~/senzing-up-demonstration-N/docker-bin/docker-environment-vars.sh`
   Give each docker container a unique port.
   Example:

    ```console
    export SENZING_DOCKER_PORT_JUPYTER=9200
    export SENZING_DOCKER_PORT_PHPPGADMIN_HTTP=9201
    export SENZING_DOCKER_PORT_PHPPGADMIN_HTTPS=9202
    export SENZING_DOCKER_PORT_PORTAINER=9203
    export SENZING_DOCKER_PORT_POSTGRES=9204
    export SENZING_DOCKER_PORT_RABBITMQ=9205
    export SENZING_DOCKER_PORT_RABBITMQ_UI=9206
    export SENZING_DOCKER_PORT_SENZING_API_SERVER=9207
    export SENZING_DOCKER_PORT_SENZING_SQLITE_WEB=9208
    export SENZING_DOCKER_PORT_SENZING_SWAGGERAPI_SWAGGER_UI=9209
    export SENZING_DOCKER_PORT_WEB_APP_DEMO=9210
    export SENZING_DOCKER_PORT_XTERM=9211
    ```



:thinking: The following tasks need to be complete before proceeding.
These are "one-time tasks" which may already have been completed.

1. The following software programs need to be installed:
    1. [docker](https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-docker.md)
    1. [senzing-up](https://github.com/Senzing/senzing-up)
