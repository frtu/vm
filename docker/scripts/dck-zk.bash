source scripts/dck-env.bash

zkshell() {
	dckbash $ZK_DCK_NAME /usr/bin/zookeeper-shell $ZOOKEEPER_HOSTNAME:$ZOOKEEPER_PORT $@
}
zkproperties() {
	dckbash $ZK_DCK_NAME cat /etc/kafka/zookeeper.properties
}
zkdatalist() {
	dckbash $ZK_DCK_NAME find /var/lib/zookeeper/data/
}
