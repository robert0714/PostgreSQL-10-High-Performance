
#!/bin/bash
# centos 7.6
value=$( grep -ic "entry" /etc/hosts )
if [ $value -eq 0 ]
then
echo "
################ hadoop-cookbook host entry ############
100.100.100.101  node1
100.100.100.102  node2 
######################################################
" > /etc/hosts
fi
sudo rpm -Uvh https://yum.postgresql.org/11/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install  -y  postgresql11-server
#sudo yum -y install yum-utils  openssl-devel bzip2-devel libffi-devel rsync
#sudo yum -y groupinstall development
#sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
#sudo yum -y install  python36u
#sudo yum -y install  python36u-pip python36u-devel
#sudo pip3.6 install --upgrade pip
#sudo pip3.6 install  argcomplete  argh      python-dateutil   setuptools  
#sudo yum -y install  barman
sudo  /usr/pgsql-11/bin/postgresql-11-setup initdb


sudo sh -c 'echo host all all     0.0.0.0/0  md5    >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host all replicator 0.0.0.0/0  md5  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c "echo listen_addresses = \'*\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo wal_level= logical   >>  /var/lib/pgsql/11/data/postgresql.conf"


sudo systemctl enable postgresql-11.service
sudo systemctl start postgresql-11.service


