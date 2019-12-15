echo "Type 'regcertgen' to generate key & cert for local server - ex: reverse-proxy-127-0-0-1.nip.io"
regcertgen() {
  mkdir -p conf/nginx/ssl
  (cd conf/nginx/ssl && gencertkey server)
}