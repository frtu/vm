MYSQL_INSTANCE=mysql-base

echo "Type 'mysqlstart' to create data folder and start mysql"
mysqlstart() {
    mkdir -p data
    docker run --rm --name ${MYSQL_INSTANCE} \
        -v $PWD/data:/var/lib/mysql \
        -e MYSQL_ROOT_PASSWORD="pass" -d\
        mysql:8.0.22
    docker logs ${MYSQL_INSTANCE} --follow
}
echo "Type 'mysqlstop' to stop mysql"
mysqlstop() {
    docker stop ${MYSQL_INSTANCE}
}
echo "Type 'mysqlrm' to delete mysql"
mysqlrm() {
    docker rm ${MYSQL_INSTANCE}
}

mysqlstart