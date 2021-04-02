# https://hub.docker.com/_/mysql?tab=tags&page=1&ordering=last_updated

IMAGE_NAME=mysql:8.0.22
CONTAINER_NAME=mysql-base
BASH_CMD=bash

mysqlinit() {
    mkdir -p db/data db/init_sql
}

echo "Type 'mysqlstart' to create data folder and start ${CONTAINER_NAME}"
mysqlstart() {
    echo "docker run --rm --name ${CONTAINER_NAME} -p 3306:3306 -v $PWD/data:/var/lib/mysql -e \"MYSQL_ROOT_PASSWORD=admin\" -e \"MYSQL_DATABASE=db\" -d ${IMAGE_NAME}"
    docker run --rm --name ${CONTAINER_NAME} \
        -p 3306:3306 \
        -e "MYSQL_ROOT_PASSWORD=admin" \
        -e "MYSQL_DATABASE=db" \
        -v $PWD/db/data:/var/lib/mysql -d\
        ${IMAGE_NAME}
    
    echo "docker logs ${CONTAINER_NAME} --follow"
    docker logs ${CONTAINER_NAME} --follow
}
echo "Type 'mysqlstop' to stop ${CONTAINER_NAME}"
mysqlstop() {
    echo "docker stop ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME}
}
echo "Type 'mysqlrm' to delete ${CONTAINER_NAME}"
mysqlrm() {
    echo "docker rm ${CONTAINER_NAME}"
    docker rm ${CONTAINER_NAME}
}

echo "Type 'mysqlbash' to open a ${BASH_CMD} ${CONTAINER_NAME}"
mysqlbash() {
    echo "docker exec -it ${CONTAINER_NAME} ${BASH_CMD} -l"
    docker exec -it ${CONTAINER_NAME} ${BASH_CMD} -l
}

mysqlinit
mysqlstart