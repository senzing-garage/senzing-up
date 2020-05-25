# senzing-up

## Preamble

At [Senzing](http://senzing.com),
we strive to create GitHub documentation in a
"[don't make me think](https://github.com/Senzing/knowledge-base/blob/master/WHATIS/dont-make-me-think.md)" style.
For the most part, instructions are copy and paste.
Whenever thinking is needed, it's marked with a "thinking" icon :thinking:.
Whenever customization is needed, it's marked with a "pencil" icon :pencil2:.
If the instructions are not clear, please let us know by opening a new
[Documentation issue](https://github.com/Senzing/senzing-environment/issues/new?template=documentation_request.md)
describing where we can improve.   Now on with the show...

## Overview

The [senzing-up.sh](senzing-up.sh) program creates and maintains an instance of Senzing in a single directory.

### Contents

1. [Expectations](#expectations)
1. [Demonstrate](#demonstrate)
    1. [Prerequisite software](#prerequisite-software)
    1. [Download](#download)
    1. [Run command](#run-command)
1. [Errors](#errors)
1. [References](#references)

#### Legend

1. :thinking: - A "thinker" icon means that a little extra thinking may be required.
   Perhaps there are some choices to be made.
   Perhaps it's an optional step.
1. :pencil2: - A "pencil" icon means that the instructions may need modification before performing.
1. :warning: - A "warning" icon means that something tricky is happening, so pay attention.

## Expectations

- **Space:** This repository and demonstration require 2 MB free disk space.
- **Time:** Budget 30 minutes to get the demonstration up-and-running, depending on CPU and network speeds.

## Demonstrate

### Prerequisite software

The following software programs need to be installed:

1. [docker](https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-docker.md)
1. [curl](https://github.com/Senzing/knowledge-base/blob/master/HOWTO/install-curl.md)

### Download

1. Get a local copy of
   [senzing-up.sh](senzing-up.sh)
   and make executable.
   Example:

    ```console
    curl -X GET \
      --output ~/senzing-up.sh \
      https://raw.githubusercontent.com/Senzing/senzing-up/master/senzing-up.sh

    chmod +x ~/senzing-up.sh
    ```

### Run command

1. Run the command.
   In this example, the Senzing instance will be put into the `~/my-first-senzing-test` folder.
   Example:

   ```console
   ~/senzing-up.sh ~/my-first-senzing-test
   ```

## Errors

1. See [docs/errors.md](docs/errors.md).

## References
