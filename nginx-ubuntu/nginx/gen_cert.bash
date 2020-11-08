echo "Type 'gen_cert' to generate key & cert for local server - ex: reverse-proxy-127-0-0-1.nip.io"
gen_cert() {
  mkdir -p ./certs
  (cd ./certs && gencertkey server)
}

gen_cert
