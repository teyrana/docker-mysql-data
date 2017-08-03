FROM mysql

# https://docs.docker.com/engine/reference/builder/


RUN mkdir -p /etc/my.cnf.d &&\
    echo "!includedir /etc/my.cnf.d/" >> /etc/my.cnf

COPY mysqld.cnf  /etc/my.cnf.d/mysqld.cnf

ENV MYSQL_HOME /home/mysql
RUN mkdir -p ${MYSQL_HOME} && cd ${MYSQL_HOME}
COPY .passwords ${MYSQL_HOME}/.passwords
RUN chown -R mysql:mysql ${MYSQL_HOME}

#RUN mysqld --initialize
