#!/bin/bash
#
# Copyright (C) 2017 Sea-Machines Inc. - All Rights Reserved
# Unauthorized copying of this file, via any medium, is strictly prohibited.
#

source .passwords
# # WARNING:
# # This script expects the following environment variables to be set:
if [ ! $ROOT_PASSWORD ]; then
    echo "!!!! ROOT_PASSWORD not set !!!!"
fi

# set these values in the environment to override these defaults

# docker config
FLAVOR='mysql'
LEVEL='master'
MASTER_IMAGE_NAME=${FLAVOR}.${LEVEL}
NETWORK_ARGS='-p 3306:3306'
PWD="$(pwd)"
VOLUME_ARGS=''
#VOLUME_ARGS=''
ROOT_PW_ARGS="-e MYSQL_ROOT_PASSWORD=${ROOT_PASSWORD}"


# Container Id file:
MASTER_CID_FILE=.${FLAVOR}.${LEVEL}.cid

# ====== ====== ====== ====== ====== ====== ======
# ======    DO NOT MODIFY BELOW THIS LINE   ======
# ====== ====== ====== ====== ====== ====== ======
build()
{
    docker build -t ${MASTER_IMAGE_NAME} .
    return 0
}

debug()
{
    echo ">> debugging start()..."
    echo "....network args: $NETWORK_ARGS"
    echo "....data args:    $VOLUME_ARGS"
    echo "....root pw:      $ROOT_PW_ARGS"
    echo "....image:        $MASTER_IMAGE_NAME"
    docker run -it $NETWORK_ARGS $VOLUME_ARGS $ROOT_PW_ARGS $MASTER_IMAGE_NAME
}

# uses: $CID_FILE, $MASTER_IMAGE_NAME
# on: success: sets $CID
# on: failure: unsets $CID
#
# Attempt to find the CID of the currently running MySQL container:
detect_container()
{
    # [1]: https://github.com/wsargent/docker-cheat-sheet#containers
    # [2]: https://docs.docker.com/engine/reference/commandline/inspect/
    if [ -f $MASTER_CID_FILE ]; then

        [[ $DEBUG ]] && echo ">> Found CID_FILE; querying docker..."

        CID=$(cat $MASTER_CID_FILE)
        RETVAL=$( docker inspect $CID --format='{{.State.Running}}' 2> /dev/null )

        if [[ $RETVAL != 'true' ]]; then
            [[ $DEBUG ]] && echo ".... Container not found."
            rm -f $MASTER_CID_FILE
            unset CID
        else
            [[ $DEBUG ]] && echo ".... Found container by id(file): $MASTER_CID_FILE => $CID"
            return 0
        fi
    fi

    if [ -z "$CID" ]; then
        [[ $DEBUG ]] && echo ">> Fail-over to searching by image-name."
        CID=$(docker ps | grep $MASTER_IMAGE_NAME | awk '{print $1}' 2> /dev/null )

        if [[ $CID ]]; then
            [[ $DEBUG ]] && echo ".... Found container by name: $MASTER_IMAGE_NAME = $CID"
            return 0
        else
            [[ $DEBUG ]] && echo ".... Container not found."
            unset CID
        fi
    fi

    return 1
}


print_usage()
{
    echo "Usage: "
    echo "    $0 [options]"
    echo " "
    echo "Commands:"
    echo "    build - build docker image and stores it locally"
    echo "    debug - starts up the image, add outputs the debug log to screen"
    echo "    setup - performs first-time-initialization"
    echo "    show - print information about image"
    echo "    start - build docker image, and start container as daemon"
    echo "    stop - stops the currently running container"
    echo ""
}

setup()
{
    echo "....user/pass=    root:$ROOT_PASSWORD"
    echo "....user/pass=    admin:$ADMIN_PASSWORD"
    echo "....user/pass=    root:$REPL_PASSWORD"
    if [ ! $ADMIN_PASSWORD ]; then
        echo "!!!! ADMIN_PASSWORD not set !!!!"
    fi
    if [ ! $REPL_PASSWORD ]; then
        echo "!!!! REPL_PASSWORD not set !!!!"
    fi
    create_admin_user
    create_replication_user
}


create_admin_user()
{
    if [[ $CID ]]; then
        echo "....creating admin user."
        docker exec $CID mysql -u root --password=${ROOT_PASSWORD}  -Bse "CREATE USER 'admin'@'%' IDENTIFIED BY '${ADMIN_PASSWORD}';GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;flush privileges;"
    fi
}
create_replication_user()
{
    if [[ $CID ]]; then
        echo "....creating replication user"
        docker exec $CID mysql -u root --password=${ROOT_PASSWORD}  -Bse "CREATE USER 'repl'@'%' IDENTIFIED BY '${REPL_PASSWORD}';GRANT ALL PRIVILEGES ON *.* TO 'repl'@'%' WITH GRANT OPTION;flush privileges;"
    fi
}

start()
{
    echo ">> starting postgres container"
    echo docker run -d --cidfile $MASTER_CID_FILE $NETWORK_ARGS $VOLUME_ARGS $ROOT_PW_ARGS $MASTER_IMAGE_NAME
    docker run -d --cidfile $MASTER_CID_FILE $NETWORK_ARGS $VOLUME_ARGS $ROOT_PW_ARGS $MASTER_IMAGE_NAME
}

stop()
{
    if [[ $CID ]]; then
        if [ -f $MASTER_CID_FILE ]; then
            docker kill $CID
            docker container rm $CID
            rm -f $MASTER_CID_FILE
        fi
    fi
}


# Start Execution:
# =====================================================

COMMAND_NAME=`echo $1 | tr '[:upper:]' '[:lower:]'`
# default to 'show'
if [ ! $COMMAND_NAME ]
then
  COMMAND_NAME='show'
fi

detect_container
# returns as $CID

if [[ $CID ]]; then
    STATE=$(docker inspect $CID --format='{{json .State}}')
fi

if [ "$COMMAND_NAME" == "debug" ]; then
  DEBUG=true
fi
if [[ $DEBUG ]]; then
    echo "====== ====== DEBUG ====== ======"
    echo "....image:        $MASTER_IMAGE_NAME"
    echo "....container id: $CID"
    echo "....cidfile:      $MASTER_CID_FILE"
    echo "....service:      "$([[ $CID ]] && echo "Up" || echo "Down")
    echo "....State:"
    echo $STATE
fi

if [[ "$COMMAND_NAME" == "help" ]] || [[ "$COMMAND_NAME" == "usage" ]]
then
    print_usage
elif [ "$COMMAND_NAME" == "build" ]; then
    build
elif [ "$COMMAND_NAME" == "debug" ]; then
    if [[ $CID ]]; then
        echo "   MySQL is already running:"
        echo $STATE
    else
        build
        debug
    fi
elif [[ "$COMMAND_NAME" == "start" ]] || [[ "$COMMAND_NAME" == "run" ]]
then
    if [[ $CID ]]; then
        echo "   MySQL is already running:"
        echo $STATE
    else
        build
        start
    fi
elif [[ "$COMMAND_NAME" == "show" ]] || [[ "$COMMAND_NAME" == "list" ]] || [[ "$COMMAND_NAME" == "status" ]]
then
    if [[ $CID ]]; then
        echo "    MySQL process info:"
        echo $STATE
    else
       echo "     !! No MySQL process found!"
    fi
elif [[ "$COMMAND_NAME" == "replicate" ]] || [[ "$COMMAND_NAME" == "repl" ]]
then
    replicate
elif [[ "$COMMAND_NAME" == "setup" ]] || [[ "$COMMAND_NAME" == "init" ]]
then
    setup
elif [ "$COMMAND_NAME" == "stop" ]; then
    if [[ $CID ]]; then
        echo "    Stopping Container: $CID"
        stop
    else
        echo "    !! No active container found !!"
    fi
elif [ "$COMMAND_NAME" == "kill" ]; then
    stop
else
    echo "    !! Command \"$COMMAND_NAME\" not recognized!"
    echo ""
    print_usage
fi
