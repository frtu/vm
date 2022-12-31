wkf-temporalite
===

## Forewords

Check [temporalite repo](https://github.com/temporalio/temporalite) for [latest version](https://github.com/temporalio/temporalite/releases).

Repo [slamdev/temporalite](https://github.com/slamdev/temporalite-container-image) is having the latest 0.3.0 as of now (jan 1st 2023).

You can use the already [built image](https://hub.docker.com/r/slamdev/temporalite/tags) or uncomment the docker-compose build to the latest version yourself.

## Usage

### Option 1 - docker compose

Start with ```docker-compose up```

You will be able to have :

* temporal : port ```7233``` namespace ```default```
* admin UI : port ```8233``` at [http://localhost:8233/](http://localhost:8233/)

### Option 2 - Start & Stop command lines

Start postgres using script :

	. run_scripts.bash

It also register many bash commands :

* ```temporalitestart``` to create data folder and start temporalite
* ```temporalitestop``` to stop temporalite
* ```temporaliterm``` to delete temporalite
* ```temporalitebash``` to open a bash cmd in temporalite

### Connection URLs

Connect to postgres using port ```7233```
