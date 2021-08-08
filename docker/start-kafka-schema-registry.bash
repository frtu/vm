source scripts/dck-kafka.bash
source scripts/dck-zk.bash

export BASH_FWK_ROOT=~/git/bash-fwk

echo "Type 'instscript' to install bash-fwk locally"
instscript() {
	echo "Install bash-fwk that contains Docker & Vagrant utilities."
	echo "$(curl -fsSL https://raw.githubusercontent.com/frtu/bash-fwk/master/autoinstaller4curl.bash)" | bash
}

echo "Type 'dckreg' to start Docker Registry Proxy"
dckreg() {
	echo "Make sure you have ** docker-compose ** installed !!"
	(cd docker-registry-proxy && exec docker-compose up)
}
echo "Type 'dckregcatalog' to get catalog from Docker Registry"
dckregcatalog() {
	echo "Pulling catalog from Docker Registry => http://localhost:5000/v2/_catalog !!"
	curl http://localhost:5000/v2/_catalog
}

echo "Type 'dckonvagrant' to start Docker on Vagrant"
dckonvagrant() {
	echo "Make sure you have ** vagrant ** installed !!"
	echo "- If you have bash-fwk, use 'vagbadd_docker_ubuntu_trusty' to pre install image."
	(cd vagrant-docker && exec vagrant up && exec dckonvagrantinit)
}
dckonvagrantinit() {
  vagrant plugin install vagrant-docker-compose
  if [[ -d $BASH_FWK_ROOT ]]; then
    echo "== Since you've install 'bash-fwk' enable it inside the VM & add docker utilities =="
    vaginst_script
    vagenabledocker
  fi
}

echo "Type 'kafstartsimple' to start kafka-simple"
kafstartplatform() {
	echo "Make sure you have ** docker-compose ** installed !!"
	(cd kafka-platform && exec docker-compose up)
	dckmport 2181
	dckmport 9092
	dckmport 8081
	dckmport 8082
	dckmport 8083
}
echo "Type 'kafstartplatform' to start kafka-platform"
kafstartsimple() {
	echo "Make sure you have ** docker-compose ** installed !!"
	(cd kafka-simple && exec docker-compose up)
	dckmport 2181
	dckmport 9092
}
