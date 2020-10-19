# senzing-up advanced

## Multi-tenancy

### First tenant

1. Use `senzing-up.sh` to create the first tenant.
   Example:

    ```console
    ~/senzing-up.sh ~/senzing-up-demonstration-1
    ```

### Next tenants

To create additional tenants, it's not necessary to run `senzing-up.sh` again.
Copying and modifying will work.
`senzing-up.sh` will perform esse

1. Copy the directory for Tenant #1 into a new directory
   Example:

    ```console
    cp --recursive ~/senzing-up-demonstration-1 ~/senzing-up-demonstration-N
    ```

1. In `~/senzing-up-demonstration-N/docker-bin/docker-environment-vars.sh`,
   specify unique ports for Tenant #N's docker containers.
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

1. In `~/senzing-up-demonstration-N/docker-bin/docker-environment-vars.sh`, change `SENZING_PROJECT_DIR`.
   Example:

    ```console
    export SENZING_PROJECT_DIR=/home/username/senzing-up-demonstration-N
    ```

1. In `~/senzing-up-demonstration-N/docker-bin/docker-environment-vars.sh`, change `SENZING_PROJECT_NAME`.
   Example:

    ```console
    export SENZING_PROJECT_NAME=tenant-N
    ```
