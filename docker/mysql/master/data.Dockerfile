FROM mysql/mysql-server:5.7

# redundant, but explicit
VOLUME /var/lib/mysql

CMD ["true"]
