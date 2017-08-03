Database Container Setup and Design
====

# Overview:

(mysqld image, master)
The database configuration file, `mysqld.cnf` is specified in this repository,
and copied into the container during build.  (overwriting the existing file.)


# Replication

[ Streaming Replication #1 ]( https://www.digitalocean.com/community/tutorials/how-to-set-up-master-slave-replication-on-postgresql-on-an-ubuntu-12-04-vps )

[ Streaming Replication #2 ]( https://severalnines.com/blog/become-postgresql-dba-how-setup-streaming-replication-high-availability )


# Data-Only Container (TODO)(NYI)

1. Tried this once, but it only produced errors.  
2. Apparently, I should be using `named volumes` instead? [[102]][[103]]

Further Reading:
- [[101]]
- [[102]]
- [[103]]
- [[104]]
- [[105]]
- [[106]]


# Documentation

Links
----
- [`docker run` Command Reference](1)
- [`docker build` Command Reference](2)


`
Copyright (C) 2017 Sea-Machines Inc. - All Rights Reserved
Unauthorized copying of this file, via any medium, is strictly prohibited.
`

[1]: https://docs.docker.com/engine/reference/run/
[2]: https://docs.docker.com/engine/reference/builder/


[101]: https://docs.docker.com/engine/tutorials/dockervolumes/
[102]: https://docs.docker.com/engine/reference/commandline/volume_create/
[103]: http://blog.arungupta.me/docker-mysql-persistence/
[104]:https://stackoverflow.com/questions/18496940/how-to-deal-with-persistent-storage-e-g-databases-in-docker
[105]:https://stackoverflow.com/questions/23544282/what-is-the-best-way-to-manage-permissions-for-docker-shared-volumes
