# https://hub.docker.com/_/ubuntu/
ARG BASE_CONTAINER=ubuntu:20.10
FROM $BASE_CONTAINER

# UNCOMMENT FOR CN
RUN sed -i "s/archive.ubuntu./mirrors.aliyun./g" /etc/apt/sources.list
RUN sed -i "s/deb.debian.org/mirrors.aliyun.com/g" /etc/apt/sources.list
RUN sed -i "s/security.debian.org/mirrors.aliyun.com\/debian-security/g" /etc/apt/sources.list

RUN apt-get update

# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#installing-a-prebuilt-debian-package-from-an-os-repository

# check log to see "nginx version: nginx/1.18.0 (Ubuntu)"
RUN apt-get install -y nginx && \
  nginx -v

# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/
COPY ./nginx/conf/ /etc/nginx/

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
