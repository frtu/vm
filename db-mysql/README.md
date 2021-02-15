mysql
===

## Usage

### Option 1 - docker compose

Start with ```docker-compose up```

You will be able to have :

* mysql : port ```3306``` default database ```db```
* phpmysql : [http://localhost:8006/](http://localhost:8006/) (root / root)

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

If you start with ```docker-compose up```, you will also have access to phpmyadmin at [http://localhost:8006/](http://localhost:8006/)

### Changing password

Edit docker-compose.yml and change the environment properties :

```
MYSQL_ROOT_PASSWORD: 'root'

MYSQL_USER: 'user'
MYSQL_PASSWORD: 'pass'
```

## Prepare DB

* Login into phpmysql : [http://localhost:8006/](http://localhost:8006/) (root / root)
* Click on the ```SQL``` tab
* Run the following table creation :

```
use db;
CREATE TABLE IF NOT EXISTS table_name(
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    content VARCHAR(255) NOT NULL
);
```

## Troubleshooting

### Public Key Retrieval is not allowed

If you use encounter ```Public Key Retrieval is not allowed``` when connecting with DBeaver, add the following User properties :

* useSSL=false
* allowPublicKeyRetrieval=true

![Fix Error - Public Key Retrieval](docs/fix_error_key_retrieval-img.png)