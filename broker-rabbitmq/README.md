rabbitmq
===

## Usage

### Option 1 - docker compose

Start with ```docker-compose up```

You will be able to have :

* rabbitmq : port ```5672```
* management console : [http://localhost:15672/](http://localhost:15672/) (admin / admin)

### Option 2 - Start & Stop command lines

Start mysql using script :

	. run_scripts.bash

It also register many bash commands :

* ```rabbitmqstart``` to create data folder and start rabbitmq
* ```rabbitmq stop``` to stop rabbitmq
* ```rabbitmq rm``` to delete rabbitmq
* ```rabbitmq bash``` to open a bash cmd in rabbitmq

Access using :

* rabbitmq : port ```5672```
* management console : [http://localhost:15672/](http://localhost:15672/) (guest / guest)

