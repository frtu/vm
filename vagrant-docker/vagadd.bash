boxexport() {
  vagexport vagrant-docker-centos7 vagrant-docker-centos7.box
  vagexportkeyvbox
}
boximport() {
  vagbadd vagrant-docker-centos7 vagrant-docker-centos7.box

  vagbls
  echo "You can use vagrant image : vagrant-docker-centos7 don't forget to import private key with vagimportkeyvbox"
}
