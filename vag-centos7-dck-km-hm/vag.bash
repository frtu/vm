echo "Type 'vaginit'"
vaginit() {
  vaginst_vbguest
  vagstart
}

echo "Type 'boxexport' to export local vag-centos7-dck-km-hm & private_key into file"
boxexport() {
  local INSTANCE_NAME=${1:-vag-centos7-dck-km-hm}
  local BOX_FILE_NAME=${2:-${INSTANCE_NAME}.box}
  vagexport ${INSTANCE_NAME} ${BOX_FILE_NAME}
  vagbadd ${INSTANCE_NAME} ${BOX_FILE_NAME}

  vagexportkeyvbox
}
