FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/sites-enabled/default

CMD ["nginx", "-g", "daemon off;"]