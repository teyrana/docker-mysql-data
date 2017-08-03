#!/bin/bash

source ./.passwords

# NOTE: This script expects:
# (1) "./.passwords" to exist, and
# (2) to export / define:
#   - ROOT_PASSWORD
#   - ADMIN_PASSWORD
#   - REPL_PASSWORD

# select location of active deployment here:
pushd docker/mysql/master/


# call script from its own directory so ancillary files may be found.
./service.sh $@

popd
