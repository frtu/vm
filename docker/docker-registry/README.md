# docker-registry

Using [Docker official registry](https://docs.docker.com/registry/deploying/)

## Usage

### docker compose

Start with ```docker-compose up```

You will be able to have :

* Docker registry (port ```5000``` insecure, for secure see below)
* Registry UI (craneoperator) : [http://localhost:5080/containers](http://localhost:5080/containers) (admin / admin)

### Connection URLs

Push image into docker-registry using port ```5000 ```

```
docker pull alpine
docker tag alpine myregistry-127-0-0-1.nip.io:5000/alpine
docker push myregistry-127-0-0-1.nip.io:5000/alpine
docker pull myregistry-127-0-0-1.nip.io:5000/alpine
```

Or if you use [bash-fwk](https://github.com/frtu/bash-fwk) :

```
docker pull alpine
dckregtagpush alpine myregistry-127-0-0-1.nip.io:5000
```

## Security concerns

### Changing password

Edit docker-compose.yml and change the environment properties :

```
- USERNAME=admin
- PASSWORD=admin
```

### Adding HTTPS domain certs

* Run generate script using : ```source gen-certs.bash```
* When asking for domain name fill :  ```myregistry-127-0-0-1.nip.io```
