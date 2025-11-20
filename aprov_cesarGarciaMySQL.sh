#!/bin/bash
set -e

echo "Comprobando conexión a internet"
ping 8.8.8.8 -c 4

echo "Procediendo a actualizar repositorios"
sudo apt update -y

echo "Procediendo a instalar MySQL"
sudo apt install -y mariadb-server
systemctl enable mariadb
systemctl start mariadb

DB_ROOT_PASS="toor"
DB_NAME="lamp_db"
DB_USER="uapp"
DB_PASS="papp"


# Permitir conexiones remotas
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

# Arrancar MySQL
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Configuramos la base de datos

# Entramos a la base de datos y creamos la tabla
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS 'uapp'@'192.168.10.1' IDENTIFIED BY 'papp';
GRANT ALL PRIVILEGES ON lamp_db.* TO 'uapp'@'192.168.10.1';
FLUSH PRIVILEGES;

USE ${DB_NAME};
CREATE TABLE users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  age INT UNSIGNED NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

# Borramos el acceso al router porque ya está todo actualizado
sudo ip route del default

# Reiniciamos SQL
sudo systemctl restart mariadb

echo "Servidor MySQL configurado correctamente"

echo "Procediendo a iniciar MySQL"
sudo systemctl start mariadb
sudo systemctl status mariadb