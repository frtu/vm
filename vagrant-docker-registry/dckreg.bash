echo "Type 'boxexport' to export local vagrant-docker-registry & private_key into file"
boxexport() {
  vagexport vagrant-docker-registry vagrant-docker-registry.box
  vagexportkeyvbox
}

echo "Type 'regcertgen' to generate key & cert for local server - ex: myregistry-127-0-0-1.nip.io"
regcertgen() {
  mkdir -p conf/registry/nginx/certs
  (cd conf/registry/nginx/certs && gencertkey server)
}

echo "Type 'startnginx nginx' to start nginx using this folder in /etc/nginx"
startnginx() {
  docker run -d --name nginx-proxy -v $1:/etc/nginx/ -p 80:80 -p 443:443 -P nginx:alpine
}