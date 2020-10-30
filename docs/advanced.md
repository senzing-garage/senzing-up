# senzing-up advanced

Advanced topics for using `senzing-up.sh`.

1. [Multi-tenancy](#multi-tenancy)
    1. [First tenant](#first-tenant)
    1. [Next tenants](#next-tenants)
1. Databases
    1. [PostgreSQL](#postgresql)
    1. [MySQL](#mysql)
    1. [MSSQL](#mssql)
    1. [Db2](#db2)

## Multi-tenancy

### First tenant

1. :pencil2: Use `senzing-up.sh` to create the first tenant.
   Example:

    ```console
    ~/senzing-up.sh ~/senzing-up-demonstration-1
    ```

### Next tenants

To create additional tenants, it's not necessary to run `senzing-up.sh` again.
Copying and modifying will work.
The copy command, `cp`, of a fresh install will give the same results as `senzing-up.sh`.

1. :pencil2: Copy the directory for Tenant #1 into a new directory
   Example:

    ```console
    cp --recursive ~/senzing-up-demonstration-1 ~/senzing-up-demonstration-N
    ```

1. :pencil2: In `~/senzing-up-demonstration-N/docker-bin/docker-environment-vars.sh`,
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

1. :pencil2: In `~/senzing-up-demonstration-N/docker-bin/docker-environment-vars.sh`, change `SENZING_PROJECT_DIR`.
   **Important:** Replace `username` with your actual user name.
   Example:

    ```console
    export SENZING_PROJECT_DIR=/home/username/senzing-up-demonstration-N
    ```

1. :pencil2: In `~/senzing-up-demonstration-N/docker-bin/docker-environment-vars.sh`, change `SENZING_PROJECT_NAME`.
   Example:

    ```console
    export SENZING_PROJECT_NAME=tenant-N
    ```

## Databases

### PostgreSQL

1. Perform steps in [Next tenants](#next-tenants).
1. :pencil2: In `docker-bin/docker-environment-vars.sh`,
   update the values of the following environment variables.
   Example:

    ```console
    export DATABASE_DATABASE=G2
    export DATABASE_HOST=${SENZING_DOCKER_HOST_IP_ADDR}
    export DATABASE_PASSWORD=postgres
    export DATABASE_PORT=5432
    export DATABASE_PROTOCOL=postgresql
    export DATABASE_USERNAME=postgres

    export SENZING_DATABASE_URL="${DATABASE_PROTOCOL}://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_DATABASE}"
    export SENZING_SQL_CONNECTION="postgresql://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}:${DATABASE_DATABASE}/"
    ```

1. :pencil2: Initialize configuration files.
   Example:

    ```console
    ~/senzing-up-demonstration-N/docker-bin/senzing-init-container.sh up
    ```

### MySQL

1. Perform steps in [Next tenants](#next-tenants).
1. :pencil2: In `docker-bin/docker-environment-vars.sh`,
   update the values of the following environment variables.
   Example:

    ```console
    export DATABASE_DATABASE=G2
    export DATABASE_HOST=${SENZING_DOCKER_HOST_IP_ADDR}
    export DATABASE_PASSWORD=g2
    export DATABASE_PORT=3306
    export DATABASE_PROTOCOL=mysql
    export DATABASE_USERNAME=g2

    export SENZING_DATABASE_URL="${DATABASE_PROTOCOL}://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_DATABASE}"
    export SENZING_SQL_CONNECTION="mysql://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/?schema=${DATABASE_DATABASE}"
    ```

1. :pencil2: Initialize configuration files.
   Example:

    ```console
    ~/senzing-up-demonstration-N/docker-bin/senzing-init-container.sh up
    ```

### MSSQL

1. Perform steps in [Next tenants](#next-tenants).
1. :pencil2: In `docker-bin/docker-environment-vars.sh`,
   update the values of the following environment variables.
   Example:

    ```console
    export DATABASE_DATABASE=G2
    export DATABASE_HOST=${SENZING_DOCKER_HOST_IP_ADDR}
    export DATABASE_PASSWORD=Passw0rd
    export DATABASE_PORT=1433
    export DATABASE_PROTOCOL=mssql
    export DATABASE_USERNAME=sa

    export SENZING_DATABASE_URL="${DATABASE_PROTOCOL}://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_DATABASE}"
    export SENZING_MSSQL_PARAMETERS="--env ODBCSYSINI=/opt/microsoft/msodbcsql17/etc --env ODBCINI=/opt/microsoft/msodbcsql17/etc/odbc.ini --user 0"
    export SENZING_SQL_CONNECTION="mssql://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_DATABASE}"
    ```

1. :pencil2: Install database driver files.
   Example:

    ```console
    ~/senzing-up-demonstration-N/docker-bin/senzing-mssql-driver-installer.sh up
    ```

1. :pencil2: Initialize configuration files.
   Example:

    ```console
    ~/senzing-up-demonstration-N/docker-bin/senzing-init-container.sh up
    ```

### Db2

1. Perform steps in [Next tenants](#next-tenants).
1. :pencil2: In `docker-bin/docker-environment-vars.sh`,
   update the values of the following environment variables.
   Example:

    ```console
    export DATABASE_DATABASE=G2
    export DATABASE_HOST=${SENZING_DOCKER_HOST_IP_ADDR}
    export DATABASE_PASSWORD=db2inst1
    export DATABASE_PORT=50000
    export DATABASE_PROTOCOL=db2
    export DATABASE_USERNAME=db2inst1

    export SENZING_DATABASE_URL="${DATABASE_PROTOCOL}://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_DATABASE}"
    export SENZING_SQL_CONNECTION="db2://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_DATABASE}"
    ```

1. :pencil2: Install database driver files.
   Example:

    ```console
    ~/senzing-up-demonstration-N/docker-bin/senzing-db2-driver-installer.sh up
    ```

1. :pencil2: Initialize configuration files.
   Example:

    ```console
    ~/senzing-up-demonstration-N/docker-bin/senzing-init-container.sh up
    ```
