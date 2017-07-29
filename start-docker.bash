source scripts/dck-kafka.bash
source scripts/dck-zk.bash

kafstartplatform() {
	(cd kafka-platform && exec docker-compose up)
	dckmport 2181
	dckmport 9092
	dckmport 8081
	dckmport 8082
	dckmport 8083
}
kafstartsimple() {
	(cd kafka-simple && exec docker-compose up)
	dckmport 2181
	dckmport 9092
}

echo "Type 'kafstartsimple' to start kafka-simple"
echo "Type 'kafstartplatform' to start kafka-platform"
