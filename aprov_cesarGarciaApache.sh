#!/bin/bash

echo "Comprobando conexión a internet"
ping 8.8.8.8 -c 4

echo "Procediendo a actualizar repositorios"
sudo apt update -y
# sudo apt upgrade -y

# Instalacion de dependencias: Apache, PHP, MySQL client, git
echo "Instalando apache, php, php-mysql, git y mysql-client"
sudo apt install -y apache2 && echo "Apache instalado correctamente"
sudo apt install -y php libapache2-mod-php php-mysql && echo "PHP instalado correctamente"
sudo apt install -y git && echo "Git instalado correctamente"
sudo apt install -y default-mysql-client && echo "mysql-client instalado correctamente"

# Clonamos el repositorio en un directorio temporal
echo "Clonando repositorio"
cd /tmp
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git

# Borramos contenidos de /html y copiamos todo el interior de /src del github a /html
sudo rm -rf /var/www/html/*
sudo cp -rf iaw-practica-lamp/src/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Configuracion base de datos en config.php
sudo sed -i "s/define('DB_HOST'.*/define('DB_HOST', '192.168.10.2');/" /var/www/html/config.php
sudo sed -i "s/define('DB_NAME'.*/define('DB_NAME', 'lamp_db');/" /var/www/html/config.php
sudo sed -i "s/define('DB_USER'.*/define('DB_USER', 'uapp');/" /var/www/html/config.php
sudo sed -i "s/define('DB_PASSWORD'.*/define('DB_PASSWORD', 'papp');/" /var/www/html/config.php

# Reiniciar Apache para aplicar cambios
sudo systemctl restart apache2

echo "Servidor Apache configurado y listo para conectar con MySQL"

echo "Procediendo a habilitar Apache"
sudo systemctl enable apache2
