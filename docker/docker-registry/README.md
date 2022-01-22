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
docker tag alpine localhost:5000/my-alpine
docker push localhost:5000/my-alpine
docker pull localhost:5000/my-alpine
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
