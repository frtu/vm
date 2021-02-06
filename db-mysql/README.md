mysql
===

## Usage

### Option 1 - docker compose

Start with ```docker-compose up```

You will be able to have :

* mysql : port 3306
* [phpmysql](http://localhost:8080/)

### Option 2 - Start & Stop command lines

Start mysql using script :

	. run_scripts.bash

It also register many bash commands :

* ```mysqlstart``` to create data folder and start mysql
* ```mysqlstop``` to stop mysql
* ```mysqlrm``` to delete mysql
* ```mysqlbash``` to open a bash cmd in mysql

### Connection URLs

Connect to mysql using port ```3306```

If you start with ```docker-compose up```, you will also have access to phpmyadmin at [http://localhost:8080/](http://localhost:8080/)

## Troubleshooting

### Public Key Retrieval is not allowed

If you use encounter ```Public Key Retrieval is not allowed``` when connecting with DBeaver, add the following User properties :

* useSSL=false
* allowPublicKeyRetrieval=true

![Fix Error - Public Key Retrieval](docs/fix_error_key_retrieval.png)