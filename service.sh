#!/bin/bash

# NOTE: This script expects:
# (1) "./.passwords" to exist, and
# (2) to export the following shell variables:
#   - ADMIN_PASSWORD
#   - BRIDGE_PASSWORD
#   - ROOT_PASSWORD
#   - REPL_PASSWORD
source ./.passwords
if [ 0 -ne "$?" ]; then
    exit 1
fi

# select location of active deployment here:
pushd docker/mysql/master/ > /dev/null

# call script from its own directory so ancillary files may be found.
./service.sh $@

popd > /dev/null
