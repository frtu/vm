# https://hub.docker.com/r/slamdev/temporalite

IMAGE_NAME=slamdev/temporalite:0.3.0
CONTAINER_NAME=temporalite
BASH_CMD=bash

echo "Type 'temporalitestart' to create data folder and start ${CONTAINER_NAME}"
temporalitestart() {
    echo "docker run --rm --name ${CONTAINER_NAME} -p 5432:5432 -v $PWD/data:/var/lib/temporaliteql/data -d ${IMAGE_NAME}"
    docker run --rm --name ${CONTAINER_NAME} \
        -p7233:7233 -p8233:8233 \
        -v $PWD/data:/var/lib/temporaliteql/data \
        -d\ ${IMAGE_NAME}
    
    echo "docker logs ${CONTAINER_NAME} --follow"
    docker logs ${CONTAINER_NAME} --follow
}
echo "Type 'temporalitestop' to stop ${CONTAINER_NAME}"
temporalitestop() {
    echo "docker stop ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME}
}
echo "Type 'temporaliterm' to delete ${CONTAINER_NAME}"
temporaliterm() {
    echo "docker rm ${CONTAINER_NAME}"
    docker rm ${CONTAINER_NAME}

    rm -Rf $PWD/data
}

echo "Type 'temporalitebash' to open a ${BASH_CMD} ${CONTAINER_NAME}"
temporalitebash() {
    echo "docker exec -it ${CONTAINER_NAME} ${BASH_CMD} -l"
    docker exec -it ${CONTAINER_NAME} ${BASH_CMD} -l
}

temporaliteinit
temporalitestart