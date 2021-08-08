# https://hub.docker.com/_/rabbitmq

CONTAINER_NAME=rabbitmq
IMAGE_NAME=${CONTAINER_NAME}:3.8.14-management
BASH_CMD=bash

echo "Type 'rabbitmqstart' to create data folder and start ${CONTAINER_NAME}"
rabbitmqstart() {
    echo "docker run --rm --name ${CONTAINER_NAME} --hostname ${CONTAINER_NAME} -p 5672:5672 -p 15672:15672 -v $PWD/${CONTAINER_NAME}/data:/var/lib/rabbitmq/mnesia/rabbit@${CONTAINER_NAME} -v $PWD/${CONTAINER_NAME}/logs:/var/log/rabbitmq/log -d ${IMAGE_NAME}"
    docker run --rm --name ${CONTAINER_NAME}  --hostname ${CONTAINER_NAME} \
        -p 5672:5672 \
        -p 15672:15672 \
        -p 15692:15692 \
        -v $PWD/${CONTAINER_NAME}/data:/var/lib/rabbitmq/mnesia/rabbit@${CONTAINER_NAME} \
        -v $PWD/${CONTAINER_NAME}/logs:/var/log/rabbitmq/log \
        -d \
        ${IMAGE_NAME}
    
    echo "docker logs ${CONTAINER_NAME} --follow"
    docker logs ${CONTAINER_NAME} --follow

    echo "DEFAULT LOGIN PWD : guest/guest" 
}
echo "Type 'rabbitmqstop' to stop ${CONTAINER_NAME}"
rabbitmqstop() {
    echo "docker stop ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME}
}
echo "Type 'rabbitmqrm' to delete ${CONTAINER_NAME}"
rabbitmqrm() {
    echo "docker rm ${CONTAINER_NAME}"
    docker rm ${CONTAINER_NAME}
}

echo "Type 'rabbitmqbash' to open a ${BASH_CMD} ${CONTAINER_NAME}"
rabbitmqbash() {
    echo "docker exec -it ${CONTAINER_NAME} ${BASH_CMD} -l"
    docker exec -it ${CONTAINER_NAME} ${BASH_CMD} -l
}

rabbitmqinit
rabbitmqstart