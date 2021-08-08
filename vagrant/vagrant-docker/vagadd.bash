echo "Type 'boxexport' to export local vagrant-docker-centos7 & private_key into file"
boxexport() {
  vagexport vagrant-docker-centos7 vagrant-docker-centos7.box
  vagexportkeyvbox
}

echo "Type 'boximport' to import vagrant-docker-centos7 into registry"
boximport() {
  vagbadd vagrant-docker-centos7 vagrant-docker-centos7.box

  vagbls
  echo "You can use vagrant image : vagrant-docker-centos7 don't forget to import private key with vagimportkeyvbox"
}
