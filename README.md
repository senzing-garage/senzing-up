# senzing-up

## Synopsis

[senzing-up.sh](senzing-up.sh) simplifies using Senzing Docker containers on Linux and macOS system.
It installs Senzing into a folder and creates shell scripts to manage tasks.

## Overview

[senzing-up.sh](senzing-up.sh) performs the following:

1. Creates a folder that will contain all artifacts.
    1. Meaning: Simply delete the folder to uninstall.
1. Installs the latest version of `senzingapi` and `senzingdata` into the folder.
    1. If folder contains earlier version of Senzing, it will be non-destructively updated.
1. Creates shell scripts for use with Senzing Docker containers.
    1. Details in [senzing-environment](https://github.com/Senzing/senzing-environment).
1. Loads Senzing Model with an example "Truth Set".
1. Launches the Senzing API Sever and Senzing Entity Search web application using a local SQLite database.

### Contents

1. [Preamble](#preamble)
    1. [Legend](#legend)
1. [Expectations](#expectations)
1. [Demonstrate](#demonstrate)
    1. [Prerequisite software](#prerequisite-software)
    1. [Download](#download)
    1. [Start web application](#start-web-application)
    1. [Stop web application](#stop-web-application)
    1. [Restart web application](#restart-web-application)
    1. [View web application](#view-web-application)
    1. [Tutorial](tutorial)
1. [Advanced](advanced)

## Preamble

At [Senzing](http://senzing.com),
we strive to create GitHub documentation in a
"[don't make me think](https://github.com/Senzing/knowledge-base/blob/master/WHATIS/dont-make-me-think.md)" style.
For the most part, instructions are copy and paste.
Whenever thinking is needed, it's marked with a "thinking" icon :thinking:.
Whenever customization is needed, it's marked with a "pencil" icon :pencil2:.
If the instructions are not clear, please let us know by opening a new
[Documentation issue](https://github.com/Senzing/template-python/issues/new?template=documentation_request.md)
describing where we can improve.   Now on with the show...

### Legend

1. :thinking: - A "thinker" icon means that a little extra thinking may be required.
   Perhaps there are some choices to be made.
   Perhaps it's an optional step.
1. :pencil2: - A "pencil" icon means that the instructions may need modification before performing.
1. :warning: - A "warning" icon means that something tricky is happening, so pay attention.

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
   In this example, the Senzing instance will be put into the `~/senzing-up-demonstration` project directory.
   Example:

    ```console
    ~/senzing-up.sh ~/senzing-up-demonstration
    ```

1. **Note:** This may take a while as many Docker images will be downloaded.
   This is a one-time cost.
   Subsequent use will use cached Docker images.

### Stop web application

1. To stop the demonstration, use `senzing-webapp-demo.sh down`.
   Example:

    ```console
    ~/senzing-up-demonstration/docker-bin/senzing-webapp-demo.sh down
    ```

### Restart web application

There are 2 ways to re-start the web application.

1. **Method #1:** Use "docker-bin/senzing-webapp-demo.sh".
   This simply starts the docker container.
   Example:

    ```console
    ~/senzing-up-demonstration/docker-bin/senzing-webapp-demo.sh up
    ```

1. **Method #2:** Use "senzing-up.sh".
   This method will prompt you for update detection
   and then will start the docker container.
   Example:

    ```console
    ~/senzing-up.sh ~/senzing-up-demonstration
    ```

### View web application

1. If deployed on a local workstation, visit [http://localhost:8251](http://localhost:8251).

### Tutorial

1. For more examples of use, visit the [tutorial](docs/tutorial.md).

## Advanced

1. For advanced examples of use, visit [advanced](docs/advanced.md).
