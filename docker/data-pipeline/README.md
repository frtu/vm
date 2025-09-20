data-pipeline
===

Start with ```docker-compose up```

Open Notebook at : [http://localhost:8888](http://localhost:8888)

### Data in motion

* Kafka-UI : [http://localhost:28080](http://localhost:28080/ui/clusters/local/all-topics)
* Flink UI : [http://localhost:28081](http://localhost:28080/ui/clusters/local/all-topics)

### Data at Rest

* PostgreSQL : port ```5432``` default database ```postgres```
* Elasticsearch : port ```9200```
* kibana : [http://localhost:5601/](http://localhost:5601/)

## PostgreSQL Config

Connect to postgres using port ```5432```

### Changing password

Edit docker-compose.yml and change the environment properties :

```
postgres_ROOT_PASSWORD: 'admin'

postgres_USER: 'username'
postgres_PASSWORD: 'pass'
```

### Auto init DB

Put your sql commands into ```./db/init/01-init.sh``` :

* Create tables DDL scripts
* Create data DML scripts
