echo "Type 'boxexport' to export local vagrant-docker-registry & private_key into file"
boxexport() {
  vagexport vagrant-docker-registry vagrant-docker-registry.box
  vagexportkeyvbox
}
