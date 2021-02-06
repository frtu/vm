# https://hub.docker.com/r/analogic/poste.io/

IMAGE_NAME=analogic/poste.io:2.2.29
CONTAINER_NAME=mailserver
BASH_CMD=bash

echo "Type 'mailstart' to create data folder and start ${CONTAINER_NAME}"
mailstart() {
    mkdir -p data
    echo "docker run --rm --name ${CONTAINER_NAME} -p 25:25 -p 80:80 -p 443:443 -p 110:110 -p 143:143 -p 465:465 -p 587:587 -p 993:993 -p 995:995 -v $PWD/data:/data -e \"TZ=Asia/Shanghai\" -e \"HTTPS=OFF\" -d ${IMAGE_NAME}"
    docker run --rm --name ${CONTAINER_NAME} \
        -p 25:25 \
        -p 80:80 \
        -p 443:443 \
        -p 110:110 \
        -p 143:143 \
        -p 465:465 \
        -p 587:587 \
        -p 993:993 \
        -p 995:995 \
        -v $PWD/data:/data \
        -e "TZ=Asia/Shanghai" -e "HTTPS=OFF" -d\
        ${IMAGE_NAME}
    
    echo "docker logs ${CONTAINER_NAME} --follow"
    docker logs ${CONTAINER_NAME} --follow
}
echo "Type 'mailstop' to stop ${CONTAINER_NAME}"
mailstop() {
    echo "docker stop ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME}
}
echo "Type 'mailrm' to delete ${CONTAINER_NAME}"
mailrm() {
    echo "docker rm ${CONTAINER_NAME}"
    docker rm ${CONTAINER_NAME}
}

echo "Type 'mailbash' to open a ${BASH_CMD} ${CONTAINER_NAME}"
mailbash() {
    echo "docker exec -it ${CONTAINER_NAME} ${BASH_CMD} -l"
    docker exec -it ${CONTAINER_NAME} ${BASH_CMD} -l
}

mailstart