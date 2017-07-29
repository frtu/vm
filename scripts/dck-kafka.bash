source scripts/dck-env.bash

kafcddata() {
	cd /var/lib/kafka/data/
}
kaftopiccreate() {
	kaftemplate "--create --topic $1 --partitions 1 --replication-factor 1 --if-not-exists"
}
kaftopicdescribe() {
	kaftemplate "--describe --topic $1"
}

kaftemplate() {
  	echo "dckbash $KAFKA_DCK_NAME \"kafka-topics $1 --zookeeper $ZOOKEEPER_HOSTNAME:$ZOOKEEPER_PORT\""
	dckbash $KAFKA_DCK_NAME "kafka-topics $1 --zookeeper $ZOOKEEPER_HOSTNAME:$ZOOKEEPER_PORT"
}
