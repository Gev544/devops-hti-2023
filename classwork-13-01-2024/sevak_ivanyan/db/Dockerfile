FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y mysql-server && \
    rm -rf /var/lib/apt/lists/*

CMD ["mysqld"]

