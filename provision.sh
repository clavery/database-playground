cat <<HERESTOP > /etc/apt/sources.list.d/pgdg.list
deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main 9.4
HERESTOP
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get -y update
apt-get -y install postgresql-9.4
sed -i "/listen_addresses/ c\listen_addresses = '*'" /etc/postgresql/9.4/main/postgresql.conf
sed -i "/^host/ a\host    all             all             0.0.0.0/0            md5\ " /etc/postgresql/9.4/main/pg_hba.conf
service postgresql restart

sudo -u postgres psql <<ENDPSQL
CREATE ROLE vagrant WITH LOGIN SUPERUSER CREATEDB CREATEROLE ENCRYPTED PASSWORD 'vagrant';
ENDPSQL

apt-get -y install redis-server
sed -i "/bind 127.0.0.1/ c\bind 0.0.0.0" /etc/redis/redis.conf
service redis-server restart

wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
cat <<HERESTOP > /etc/apt/sources.list.d/elasticsearch.list
deb http://packages.elasticsearch.org/elasticsearch/1.3/debian stable main
HERESTOP
apt-get -y update
apt-get -y install elasticsearch openjdk-7-jre-headless 
update-rc.d elasticsearch defaults 95 10
sudo service elasticsearch restart

