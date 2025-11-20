# Práctica de creación de Pila LAMP de dos niveles

En esta práctica, utilizaremos el repositorio https://github.com/josejuansanchez/iaw-practica-lamp junto a nuestro propio archivo VagrantFile y dos scripts de aprovisionamiento en BASH, para levantar una infraestructura con stack LAMP, a dos niveles.

## Objetivo

El objetivo de esta práctica es aprender a crear una infraestructura con stack LAMP, a dos niveles, utilizando VagrantFile y scripts de aprovisionamiento en BASH.

## Requisitos

- Tener instalado VirtualBox
- Tener instalado Vagrant
- Tener instalado Git
- Tener conexión a internet para instalar paquetes y hacer un git pull desde la máquina desplegada

## Desarrollo

### Preparación

1. Una vez instalados los requisitos, creamos una carpeta para trabajar en ella, que podemos abrir en nuestro entorno de desarrollo favorito (como Visual Studio Code).
2. Hacemos "git init" y "vagrant init" para inicializar el repositorio y el archivo VagrantFile.
3. Modificamos el VagrantFile para que podamos lanzar las máquinas pertinentes. Aquí el script al completo:

---

    Vagrant.configure("2") do |config|

        config.vm.box = "debian/bookworm64"
        config.vm.box_version = "12.20250126.1"
        
        config.vm.define "cesarGarciaApache" do |cesarGarciaApache|
            cesarGarciaApache.vm.hostname = "cesarGarciaApache"
            cesarGarciaApache.vm.network "private_network", ip: "192.168.10.1", virtualbox__intnet: "redinterna"
            cesarGarciaApache.vm.network "forwarded_port", guest: 80, host: 8080
            cesarGarciaApache.vm.provision "shell", path: "aprov_cesarGarciaApache.sh"
        end

        config.vm.define "cesarGarciaMySQL" do |cesarGarciaMySQL|
            cesarGarciaMySQL.vm.hostname = "cesarGarciaMySQL"
            cesarGarciaMySQL.vm.network "private_network", ip: "192.168.10.2", virtualbox__intnet: "redinterna"
            cesarGarciaMySQL.vm.provision "shell", path: "aprov_cesarGarciaMySQL.sh"
        end
    end

---

4. Añadimos los scripts de aprovisionamiento con todos los pasos necesarios

---

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

---

