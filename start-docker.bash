source scripts/dck-kafka.bash

kafstartplatform() {
	(cd kafka-platform && exec docker-compose up)
}
kafstartsimple() {
	(cd kafka-simple && exec docker-compose up)
}

echo "Type 'kafstartsimple' to start kafka-simple"
echo "Type 'kafstartplatform' to start kafka-platform"
