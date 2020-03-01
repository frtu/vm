# https://hub.docker.com/_/nginx/
FROM nginx:alpine

# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/
COPY ./conf/nginx/ /etc/nginx/

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
