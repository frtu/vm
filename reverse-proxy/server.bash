echo "Type 'nginxinit' to generate key & cert for local server - ex: reverse-proxy-127-0-0-1.nip.io"
nginxinit() {
  mkdir -p conf/nginx/certs
  (cd conf/nginx/certs && gencertkey server)
}

echo "Type 'nginxstart' to start nginx using this folder in /etc/nginx"
nginxstart() {
  (cd conf && docker run -d --name nginx-proxy -v nginx:/etc/nginx/ -p 80:80 -p 443:443 -P nginx:alpine)
}