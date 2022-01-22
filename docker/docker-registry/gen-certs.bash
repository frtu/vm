echo "Generate key & cert for local server - ex: myregistry-127-0-0-1.nip.io"
mkdir -p conf/registry/certs
(cd conf/registry/certs && gencertkey server)

echo "=== Don't forget to UNCOMMENT certs in your docker-compose.yml ==="
