# senzing-up

## Overview

[senzing-up.sh](senzing-up.sh) launches the Senzing Entity Search web application using a local SQLite database.

### Contents

1. [Expectations](#expectations)
1. [Demonstrate](#demonstrate)
    1. [Prerequisite software](#prerequisite-software)
    1. [Download](#download)
    1. [Start web application](#start-web-application)
    1. [View web application](#view-web-application)

## Expectations

- **Space:** The demonstration requires 6 GB free disk space.
- **Time:** Budget 30 minutes to get the demonstration up-and-running, depending on CPU and network speeds.

## Demonstrate

### Prerequisite software

:thinking: The following tasks need to be complete before proceeding.
These are "one-time tasks" which may already have been completed.

1. The following software programs need to be installed and running on the workstation:
    1. [docker](https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-docker.md)
        1. Verify.
           Example:

            ```console
            sudo docker run hello-world
            ```

        1. :warning: **macOS:** - Verify sufficient resources.
            1. macOS > Docker desktop > "Preferences..." > "Resources" > "Advanced"
                1. **CPUs:** 4
                1. **Memory:** 4 GB
                1. **Swap:** 1 GB
                1. **Disk image size:** 60 GB
            1. Docker desktop > "Preferences..." > "Kubernetes"
                1. Uncheck "Enable Kubernetes"
            1. Click "Apply & Restart"

    1. [curl](https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-curl.md)
        1. Verify.
           Example:

            ```console
            curl --version
            ```

    1. [python3](https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-python-3.md)
        1. Verify.
           Example:

            ```console
            python3 --version
            ```

### Download

1. Get a local copy of
   [senzing-up.sh](https://raw.githubusercontent.com/Senzing/senzing-up/master/senzing-up.sh)
   and make executable.
   Example:

    ```console
    curl -X GET \
      --output ~/senzing-up.sh \
      https://raw.githubusercontent.com/Senzing/senzing-up/master/senzing-up.sh

    chmod +x ~/senzing-up.sh
    ```

### Start web application

1. Command format: **`senzing-up.sh <project-directory>`**
1. Run the command.
   In this example, the Senzing instance will be put into the `~/my-first-senzing-test` project directory.
   Example:

   ```console
   ~/senzing-up.sh ~/my-first-senzing-test
   ```

### View web application

1. Visit [http://localhost:8251](http://localhost:8251).

1. For a tour of sample data, visit
   [Synthetic Truth Sets](https://senzing.zendesk.com/hc/en-us/articles/360047940434-Synthetic-Truth-Sets).
