# Logical Replication
## Node1

```bash

[root@node1 vagrant]# su - postgres -c "psql"
psql (11.5)
Type "help" for help.

postgres=# create database db1;

postgres=# \list
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 db1       | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)

postgres=# \connect db1
You are now connected to database "db1" as user "postgres".
db1=# 

db1# create ROLE replicator REPLICATION LOGIN PASSWORD 'linux';
CREATE ROLE
db1=# grant ALL ON mynames to replicator;
GRANT
db1=# create table mynames (id int not null primary key, name text);
CREATE TABLE

```

# Node2

```bash

[root@node2 vagrant]# su - postgres -c "psql"
psql (11.5)
Type "help" for help.

postgres=# create database db2;

postgres=# \list
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 db2       | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)

postgres=# \connect db2
You are now connected to database "db2" as user "postgres".
db2=# 
db2=# create table mynames (id int not null primary key, name text);
CREATE TABLE
db2=# create subscription mynames_sub CONNECTION 'dbname=db1 host=node1 user=replicator password=password' PUBLICATION mynames_pub;
CREATE SUBSCRIPTION
```

Now now enter some data on node1
```bash
db1=# insert into mynames values(1,'micky mouse');
INSERT 0 1
```

..and we see the same data on node2:

```bash
db2=# select * from mynames ;
id  |name
----+-------------
1   | micky mouse
```
