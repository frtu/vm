echo "Type 'nginxinit' to generate key & cert for local server - ex: reverse-proxy-127-0-0-1.nip.io"
nginxinit() {
  mkdir -p conf/nginx/certs
  (cd conf/nginx/certs && gencertkey server)
}

echo "Type 'nginxstart' to start nginx using this folder in ./conf/nginx/"
nginxstart() {
  (cd conf && docker run -d --name nginx-proxy -v nginx:/etc/nginx/ -p 80:80 -p 443:443 -P nginx:alpine)
}

echo "Type 'nginxbuild' to build nginx using this folder in ./conf/nginx/"
nginxbuild() {
  echo "Usage : nginxbuild [IMAGE_NAME|nginx-bridge]"

  local IMAGE_NAME=${1:-nginx-bridge}
  docker build --force-rm=true --no-cache=true -t ${IMAGE_NAME} .
}

echo "Type 'nginxtagpush' to tag and push docker image"
nginxtagpush() {
  # MIN NUM OF ARG
  if [[ "$#" < "1" ]]; then
      echo "Usage : nginxtagpush 'DOCKER_REGISTRY_URL:myregistry-127-0-0-1.nip.io:5000' [IMAGE_NAME|nginx-bridge]" >&2
      return 1
  fi

  local DOCKER_REGISTRY_URL=$1
  local IMAGE_NAME=${2:-nginx-bridge}

  docker tag ${IMAGE_NAME} ${DOCKER_REGISTRY_URL}
  docker push ${DOCKER_REGISTRY_URL}
}

echo "Type 'nginxchart' to deploy chart"
nginxchart() {
  # https://docs.bitnami.com/kubernetes/how-to/create-your-first-helm-chart/
  helm install ./nginx-bridge
}
