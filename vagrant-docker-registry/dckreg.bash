echo "Type 'boxexport' to export local vagrant-docker-registry & private_key into file"
boxexport() {
  vagexport vagrant-docker-registry vagrant-docker-registry.box
  vagexportkeyvbox
}

echo "Type 'reginit' to generate key & cert for local server - ex: myregistry-127-0-0-1.nip.io"
reginit() {
  mkdir -p conf/registry/certs
  (cd conf/registry/certs && gencertkey server)
}
