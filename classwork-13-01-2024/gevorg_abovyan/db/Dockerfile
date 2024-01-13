FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y mysql-server && \
    rm -rf /var/lib/apt/lists/*

COPY password.txt /passwords/mysql-root-password.txt

CMD ["mysqld"]

