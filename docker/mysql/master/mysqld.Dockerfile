FROM mysql/mysql-server:5.7

# https://docs.docker.com/engine/reference/builder/


# N.B. matches data dir defined in parent image
ENV MYSQL_DATA_DIR /var/lib/mysql

RUN mkdir -p /etc/my.cnf.d &&\
    echo "!includedir /etc/my.cnf.d/" >> /etc/my.cnf

COPY mysqld.cnf  /etc/my.cnf.d/mysqld.cnf
