#!/bin/bash
#
# Copyright (C) 2017 Sea-Machines Inc. - All Rights Reserved
# Unauthorized copying of this file, via any medium, is strictly prohibited.
#

# # WARNING:
# # This script expects the following environment variables to be set:
if [ ! $ROOT_PASSWORD ]; then
    echo "!!!! ROOT_PASSWORD not set !!!!"
    echo ".... does $PROJECT_ROOT/.passwords exist?"
fi

# set these values in the environment to override these defaults

# docker config
FLAVOR='mysql'
LEVEL='master'

PWD="$(pwd)"

# Data Volume Setup
DATA_IMAGE=data-${LEVEL}
DATA_DOCKERFILE="Dockerfile.data"
DATA_CID_FILE=.data.cid

# Database Process Volume Setup
PROCESS_IMAGE="proc-${FLAVOR}-${LEVEL}"
PROCESS_DOCKERFILE="Dockerfile.process"
NETWORK_ARGS="-p 3306:3306"
VOLUME_ARGS="--volumes-from <not-yet-set>"
ROOT_PW_ARGS="-e MYSQL_ROOT_PASSWORD=${ROOT_PASSWORD}"
PROCESS_CID_FILE=.proc.cid


build()
{
    docker build -t ${DATA_IMAGE} -f ${DATA_DOCKERFILE} .
    docker build -t ${PROCESS_IMAGE} -f ${PROCESS_DOCKERFILE} .
}

debug()
{
    echo ">> debugging start()..."
    echo "....container:    $DATA_CONTAINER"
    echo "....source image: $DATA_IMAGE"
    # https://docs.docker.com/engine/reference/commandline/create/
    # docker create --name $DATA_CONTAINER $DATA_IMAGE

    if [[ $DATA_CID ]]; then
        VOLUME_ARGS="--volumes-from ${DATA_CID}"
    fi

    echo "....network args: $NETWORK_ARGS"
    echo "....data args:    $VOLUME_ARGS"
    echo "....root pw:      $ROOT_PW_ARGS"
    echo "....image:        $PROCESS_IMAGE"
    # https://docs.docker.com/engine/reference/run/
    # docker run -it --rm $NETWORK_ARGS $PROCESS_VOLUME_ARGS $ROOT_PW_ARGS $PROCESS_IMAGE
}


# uses: $PROCESS_CID_FILE, $PROCESS_IMAGE
# on: success: sets $PROCESS_CID
# on: failure: unsets $PROCESS_CID
#
# Attempt to find the CID of the currently running MySQL container:
# [1]: https://github.com/wsargent/docker-cheat-sheet#containers
# [2]: https://docs.docker.com/engine/reference/commandline/inspect/
detect_container()
{
    __CID=$1
    CID_FILE=$2
    IMAGE=$3

    [[ $DEBUG ]] && echo ">> Attempting to detect container from: $CID_FILE"

    # for example.  need to change this later...
    eval $__CID="'$myresult'"

    if [ -f $CID_FILE ]; then
        [[ $DEBUG ]] && echo "    >> Found CID_FILE; querying docker..."

        CID=$(cat $CID_FILE)
        STATUS=$( docker inspect $CID --format='{{.State.Status}}' 2> /dev/null )

        if [[ "$STATUS" == 'running' ]] || [[ "$STATUS" == 'created' ]]; then
            [[ $DEBUG ]] && echo "        Found container by id(file): $CID_FILE => $CID"
            eval $__CID="$CID"
            return 0
        else
            [[ $DEBUG ]] && echo "        Container not found."
            # rm -f $CID_FILE
            unset CID
        fi
    fi

    if [ -z "$CID" ]; then
        [[ $DEBUG ]] && echo "    >> Fail-over to searching by image-name."
        CID=$(docker ps | grep $IMAGE | awk '{print $1}' 2> /dev/null )

        if [[ $CID ]]; then
            [[ $DEBUG ]] && echo "        Found container by name: $IMAGE = $CID"
            eval $__CID="$CID"
            return 0
        else
            [[ $DEBUG ]] && echo "        Container not found."
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
    echo "....user/pass=    admin:$ADMIN_PASSWORD"
    echo "....user/pass=    bridge:$BRIDGE_PASSWORD"
    echo "....user/pass=    repl:$REPL_PASSWORD"
    echo "....user/pass=    root:$ROOT_PASSWORD"
    if [ ! $ADMIN_PASSWORD ]; then
        echo "!!!! ADMIN_PASSWORD not set !!!!"
    fi
    if [ ! $BRIDGE_PASSWORD ]; then
        echo "!!!! BRIDGE_PASSWORD not set !!!!"
    fi
    if [ ! $REPL_PASSWORD ]; then
        echo "!!!! REPL_PASSWORD not set !!!!"
    fi
    if [[ $PROCESS_CID ]]; then
      create_admin_user
      create_bridge_user
      create_repl_user
    fi
}


create_admin_user()
{
    echo "....creating admin user."
    docker exec $PROCESS_CID mysql -u root --password=${ROOT_PASSWORD}  -Bse "CREATE USER 'admin'@'%' IDENTIFIED BY '${ADMIN_PASSWORD}';GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;flush privileges;"
}
create_bridge_user()
{
    echo "....creating bridge user"
    docker exec $PROCESS_CID mysql -u root --password=${ROOT_PASSWORD}  -Bse "CREATE USER 'bridge'@'%' IDENTIFIED BY '${BRIDGE_PASSWORD}';GRANT ALL PRIVILEGES ON *.* TO 'repl'@'%' WITH GRANT OPTION;flush privileges;"
}
create_repl_user()
{
    echo "....creating repl user"
    docker exec $PROCESS_CID mysql -u root --password=${ROOT_PASSWORD}  -Bse "CREATE USER 'repl'@'%' IDENTIFIED BY '${REPL_PASSWORD}';GRANT ALL PRIVILEGES ON *.* TO 'repl'@'%' WITH GRANT OPTION;flush privileges;"
}


create_data_container(){
    if [ ! $DATA_CID ]; then
        echo ">> creating data container"
        docker create --cidfile ${DATA_CID_FILE} $DATA_IMAGE
    fi
}
start_process_container()
{
    echo ">> starting postgres container"
    VOLUME_ARGS="--volumes-from ${DATA_CID}"
    docker run -d --rm --cidfile ${PROCESS_CID_FILE} $NETWORK_ARGS $PROCESS_VOLUME_ARGS $ROOT_PW_ARGS $PROCESS_IMAGE
}

stop_process_container()
{
    if [[ $PROCESS_CID ]]; then
        if [ -f $PROCESS_CID_FILE ]; then
            docker kill $PROCESS_CID
            # docker container rm $PROCESS_CID
            rm -f $PROCESS_CID_FILE
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

detect_container DATA_CID $DATA_CID_FILE $DATA_IMAGE
# returns container id in '$DATA_CID'

detect_container PROCESS_CID $PROCESS_CID_FILE $PROCESS_IMAGE
# returns container id in '$PROCESS_CID'

if [ "$COMMAND_NAME" == "debug" ]; then
  DEBUG=true
fi

if [[ $DATA_CID ]]; then
    DATA_STATUS=$(docker inspect $DATA_CID --format='{{json .State.Status}}')
else
    DATA_STATUS='<none>'
fi
if [[ $PROCESS_CID ]]; then
    PROCESS_STATUS=$(docker inspect $PROCESS_CID --format='{{json .State.Status}}')
else
    PROCESS_STATUS='<none>'
fi

if [[ $DEBUG ]]; then

    echo "====== ====== DEBUG  ====== ======"
    echo "    data image:   $DATA_IMAGE"
    echo "         cid:     $DATA_CID"
    echo "         cidfile: $DATA_CID_FILE"
    echo "         state:   $DATA_STATUS"
    echo "    proc image:   $PROCESS_IMAGE"
    echo "         cid:     $PROCESS_CID"
    echo "         cidfile: $PROCESS_CID_FILE"
    echo "         state:   $PROCESS_STATUS"
    echo "====== ====== ====== ====== ======"
fi

if [[ "$COMMAND_NAME" == "connect" ]] || [[ "$COMMAND_NAME" == "mysql" ]]
then
    if [[ $PROCESS_CID ]]; then
        docker exec -it $PROCESS_CID mysql -u root --password=${ROOT_PASSWORD}
    fi
elif [[ "$COMMAND_NAME" == "help" ]] || [[ "$COMMAND_NAME" == "usage" ]]
then
    print_usage
elif [ "$COMMAND_NAME" == "build" ]; then
    build
elif [ "$COMMAND_NAME" == "debug" ]; then
    if [[ $PROCESS_CID ]]; then
        echo "   MySQL is already running: $PROCESS_STATUS"
    else
        build
        debug
    fi
elif [[ "$COMMAND_NAME" == "start" ]] || [[ "$COMMAND_NAME" == "run" ]]
then
    if [[ $PROCESS_CID ]]; then
        echo "   MySQL is already running:  $PROCESS_STATUS"
    else
        build
        create_data_container
        start_process_container
    fi
elif [[ "$COMMAND_NAME" == "show" ]] || [[ "$COMMAND_NAME" == "list" ]] || [[ "$COMMAND_NAME" == "status" ]]
then
    if [[ $DATA_CID ]]; then
        echo "    data container:"
        echo "        $DATA_STATUS : $DATA_CID"
    else
        echo "    !! No data container found !!"
    fi
    if [[ $PROCESS_CID ]]; then
        echo "    MySQL process:"
        echo "        $PROCESS_STATUS : $PROCESS_CID"
    else
        echo "    !! No MySQL process found !!"
    fi
elif [[ "$COMMAND_NAME" == "setup" ]] || [[ "$COMMAND_NAME" == "init" ]]
then
    setup
elif [ "$COMMAND_NAME" == "stop" ]; then
    if [[ $PROCESS_CID ]]; then
        echo "    Stopping Container..."
        stop_process_container
    else
        echo "    !! No active container found !!"
    fi
elif [ "$COMMAND_NAME" == "kill" ]; then
    stop_process_container
else
    echo "    !! Command \"$COMMAND_NAME\" not recognized!"
    echo ""
    print_usage
fi
