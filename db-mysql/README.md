mysql
===

Start mysql using script :

	. run_scripts.bash

It also register many bash commands :

* ```mysqlstart``` to create data folder and start mysql
* ```mysqlstop``` to stop mysql
* ```mysqlrm``` to delete mysql
* ```mysqlbash``` to open a bash cmd in mysql

## Troubleshooting

### Public Key Retrieval is not allowed

If you use encounter ```Public Key Retrieval is not allowed``` when connecting with DBeaver, add the following User properties :

* useSSL=false
* allowPublicKeyRetrieval=true

![Fix Error - Public Key Retrieval](docs/fix_error_key_retrieval.png)