# Logical Replication
## WebConsole

```bash
docker pull dpage/pgadmin4
docker run -p 80:80 \
        -e "PGADMIN_DEFAULT_EMAIL=user@domain.com" \
        -e "PGADMIN_DEFAULT_PASSWORD=SuperSecret" \
        -d dpage/pgadmin4
```

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
db1=# show wal_level;
wal_level
-----------
logical
db1# create ROLE replicator REPLICATION LOGIN PASSWORD 'linux';
CREATE ROLE
db1=# create table mynames (id int not null primary key, name text);
CREATE TABLE
db1=# grant ALL ON mynames to replicator;
GRANT
db1=# create publication mynames_pub for table mynames;
CREATE PUBLICATION
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
db2=# create subscription mynames_sub CONNECTION 'dbname=db1 host=node1 user=replicator password=linux' PUBLICATION mynames_pub;
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

And that's it.
Another thing we can do is change data locally on the slave without affecting the master;
here is an example on Node 2 :

```bash
db2=# insert into mynames values(2,'minni');
INSERT 0 1
db2=# select * from mynames ;
id | name
----+-------------
 1 | micky mouse
 2 | minni
```

and on Node 1 we still have old data:

```bash
db1=# select * from mynames ;
 id | name
----+-------------
  1 | micky mouse
```
If we want to resynchronize the slave with the master, we have to recreate the table and refresh the SUBSCRIPTION :

```bash
db2=# drop table mynames ;
DROP TABLE
db2=# create table mynames (id int not null primary key, name text);
CREATE TABLE
db2=# alter subscription mynames_sub refresh publication;
ALTER SUBSCRIPTION
db2=# select * from mynames ;
 id | name
----+-------------
  1 | micky mouse
```
Logical replication currently has the following restrictions or missing functionality. These might be addressed in future releases:
1.  The database schema and DDL commands are not replicated
1.  Sequence data is not replicated
1.  TRUNCATE commands are not replicated
1.  Large objects are not replicated
1.  Replication is only possible from base tables to base tables

That is, the tables on the publication and on the subscription side must be normal tables, not views, materialized views, partition root tables, or foreign tables. In the case of partitions, you can therefore replicate a partition hierarchy one-to-one, but you cannot currently replicate to a differently partitioned setup. Attempts to replicate tables other than base
tables will result in an error.

### error log location

```bash
[root@node1 vagrant]# cat  /var/lib/pgsql/11/data/log/postgresql-{random}.log
2019-09-06 02:01:53.615 UTC [13987] DETAIL:  User "postgres" has no password assigned.
	Connection matched pg_hba.conf line 90: "host all all 0.0.0.0/0 md5"
2019-09-06 02:01:55.611 UTC [13988] FATAL:  password authentication failed for user "postgres"
2019-09-06 02:01:55.611 UTC [13988] DETAIL:  User "postgres" has no password assigned.
	Connection matched pg_hba.conf line 90: "host all all 0.0.0.0/0 md5"
2019-09-06 02:01:57.613 UTC [13989] FATAL:  password authentication failed for user "postgres"
2019-09-06 02:01:57.613 UTC [13989] DETAIL:  User "postgres" has no password assigned.
	Connection matched pg_hba.conf line 90: "host all all 0.0.0.0/0 md5"

```
