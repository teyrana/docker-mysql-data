Database Setup:
====

# Summary
This repo will setup local docker instances of a `mysql` image. (currently
using the [official image](https://hub.docker.com/_/mysql/))

The attached script wraps this container, automating the start and stop steps of
a mysql process container: building in a local config file, building, and mapping
to a data-volume container, and automatically testing for existence of running
containers/images.


# Requirements:
Docker  (Tested on: 17.06.0-ce, build 02c1d87)

# Basic Usage:
Basic commands are handled out-of-the-box, with bash and docker.

- Start Database: ```./service.sh start```
- Stop Database:  ```./service.sh stop```

These spin-up and shut down corresponding docker images, which may be inspected
via standard docker commands.
