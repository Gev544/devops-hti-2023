FROM ubuntu:20.04

RUN apt-get -y update && apt-get -y install nginx

COPY nginx.conf /etc/nginx/sites-enabled/default

CMD ["nginx", "-g", "daemon off;"]