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
        cesarGarciaApache.vm.network "private_network", ip: "192.168.10.5", virtualbox__intnet: "redinterna"
        cesarGarciaApache.vm.network "forwarded_port", guest: 80, host: 8080
        cesarGarciaApache.vm.provision "shell", path: "aprov_cesarGarciaApache.sh"
        end

        config.vm.define "cesarGarciaMySQL" do |cesarGarciaMySQL|
        cesarGarciaMySQL.vm.hostname = "cesarGarciaMySQL"
        cesarGarciaMySQL.vm.network "private_network", ip: "192.168.10.6", virtualbox__intnet: "redinterna"
        cesarGarciaMySQL.vm.provision "shell", path: "aprov_cesarGarciaMySQL.sh"
        end

    end

---

4. Añadimos el script de aprovisionamiento para la máquina Apache con todos los pasos necesarios

```bash
    #!/bin/bash

    echo "Comprobando conexión a internet"
    ping 8.8.8.8 -c 4

    set -e
    export DEBIAN_FRONTEND=noninteractive

    echo "==> Provisionamiento de servidor web (Apache + PHP)"

    # Se actualizan los repositorios
    echo "Procediendo a actualizar repositorios"
    sudo apt update -y

    # Se instalan las dependencias: Apache, PHP, MySQL client, git
    echo "Instalando apache, php, php-mysql, git, unzip y mysql-client"
    sleep 1
    sudo apt install unzip -y && echo "Unzip instalado correctamente"
    sleep 1
    sudo apt install -y apache2 && echo "Apache instalado correctamente"
    sleep 1
    sudo apt install -y php libapache2-mod-php php-mysql && echo "PHP instalado correctamente"
    sleep 1
    sudo apt install -y git && echo "Git instalado correctamente"
    sleep 1
    sudo apt install -y mariadb-client && echo "mariadb-client instalado correctamente"
    sleep 1


    # Se clona o se actualiza la aplicación
    APP_DIR="/var/www/html/iaw-practica-lamp"

    if [ ! -d "$APP_DIR" ]; then
        git clone https://github.com/josejuansanchez/iaw-practica-lamp "$APP_DIR"
    else
        echo "Repositorio ya existe, actualizando..."
        cd "$APP_DIR"
        git pull
    fi

    # Configurar permisos seguros
    chown -R www-data:www-data "$APP_DIR"
    find "$APP_DIR" -type d -exec chmod 755 {} \;
    find "$APP_DIR" -type f -exec chmod 644 {} \;

    # Configurar Apache
    cat > /etc/apache2/sites-available/iaw-practica.conf <<EOF
    <VirtualHost *:80>
        DocumentRoot $APP_DIR/src
        <Directory $APP_DIR/src>
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>
    EOF

    # Se deshabilita el sitio por defecto y se habilita el nuevo
    a2dissite 000-default.conf
    a2ensite iaw-practica.conf
    a2enmod rewrite
    systemctl restart apache2

    # Se modifica el config.php automáticamente
    CONFIG_FILE="$APP_DIR/src/config.php"

    cat > "$CONFIG_FILE" <<'EOF'
    <?php
    define('DB_HOST', '192.168.10.6');   // IP privada de la VM DB
    define('DB_NAME', 'iawdb');           // nombre de la base de datos
    define('DB_USER', 'iawuser');         // usuario de la DB
    define('DB_PASSWORD', 'iawpass');     // contraseña del usuario

    $mysqli = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

    if (!$mysqli) {
        die("Connection failed: " . mysqli_connect_error());
    }
    ?>
    EOF

    # Se asegura que los permisos del archivo config.php sean correctos
    chown www-data:www-data "$CONFIG_FILE"
    chmod 644 "$CONFIG_FILE"

    echo "==> Archivo config.php actualizado correctamente."
    echo "==> Web Provisionamiento completado!"
    echo "==> Accede en: http://localhost:8080/"

    echo "Procediendo a rehabilitar Apache"
    sudo systemctl restart apache2

    sudo systemctl status apache2
```

5. Añadimos el script de aprovisionamiento para la máquina MySQL con todos los pasos necesarios

```bash

    #!/usr/bin/env bash

    # En cualquier caso de error, para completamente
    set -e
    # Se configura el entorno para que no se pida confirmación
    export DEBIAN_FRONTEND=noninteractive

    echo "==> Provisionando el servidor de base de datos (MariaDB)"

    # Se actualizar e instalar MariaDB
    apt-get update -y
    apt-get install -y mariadb-server && echo "MariaDB instalado correctamente"
    sleep 1

    # Se configura MariaDB para escuchar en IP privada
    sed -i "s/^bind-address.*/bind-address = 192.168.10.6/" /etc/mysql/mariadb.conf.d/50-server.cnf
    systemctl restart mariadb

    # Se crea la base de datos, usuario y datos iniciales
    mysql -u root <<MYSQL_SCRIPT
    -- Crear base de datos
    CREATE DATABASE IF NOT EXISTS iawdb CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

    -- Crear usuario y permisos
    CREATE USER IF NOT EXISTS 'iawuser'@'192.168.10.%' IDENTIFIED BY 'iawpass';
    GRANT ALL PRIVILEGES ON iawdb.* TO 'iawuser'@'192.168.10.%';
    FLUSH PRIVILEGES;

    -- Crear tabla de usuarios
    USE iawdb;
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL,
        fecha_registro DATE DEFAULT CURRENT_DATE
    );

    -- Insertar datos de ejemplo
    INSERT INTO users (nombre, email) VALUES
    ('Ana Torres', 'ana.torres@example.com'),
    ('Luis Gómez', 'luis.gomez@example.com'),
    ('Marta Ruiz', 'marta.ruiz@example.com');
    MYSQL_SCRIPT && echo "==> ¡Provisionamiento de la base de datos completado con datos iniciales!"

    sudo ip route del default
    
```

6. Levantamos las máquinas

```bash
vagrant up
```

7. Navegamos a localhost:8080 para comprobar que la web funciona correctamente

![Prueba de la web](https://raw.githubusercontent.com/cgarciap58/practica_pila_LAMP_CGP/main/captura_stack_LAMP.png)


## Explicación de los scripts

### Script aprovisionamiento de la máquina Apache

1. Comprobación de conexión a Internet

Antes de iniciar cualquier instalación, el script verifica que la máquina tenga conectividad.

```bash
ping 8.8.8.8 -c 4
```

2. Actualización de repositorios

```bash
sudo apt update -y
```

3. Instalación de paquetes

Cada echo se lanza solo cuando se ha instalado el paquete correctamente.

```bash
sudo apt install unzip -y && echo "Unzip instalado correctamente"
sleep 1
sudo apt install -y apache2 && echo "Apache instalado correctamente"
sleep 1
sudo apt install -y php libapache2-mod-php php-mysql && echo "PHP instalado correctamente"
sleep 1
sudo apt install -y git && echo "Git instalado correctamente"
sleep 1
sudo apt install -y mariadb-client && echo "mariadb-client instalado correctamente"
sleep 1
```

4. Clonado o actualización del repositorio

Se crea una variable que almacena la ruta del directorio de la aplicación.
Si el directorio no existe, se clona el repositorio.
Si el directorio existe, se actualiza el repositorio con git pull.

```bash
APP_DIR="/var/www/html/iaw-practica-lamp"

if [ ! -d "$APP_DIR" ]; then
    git clone https://github.com/josejuansanchez/iaw-practica-lamp "$APP_DIR"
else
    echo "Repositorio ya existe, actualizando..."
    cd "$APP_DIR"
    git pull
fi
```

5. Configuración de permisos

Se asegura que los permisos del archivo config.php sean correctos.
Permisos totales sobre el directorio y permisos de lectura y ejecución para el usuario www-data.
A los demás

```bash
chown -R www-data:www-data "$APP_DIR"
find "$APP_DIR" -type d -exec chmod 755 {} \;
find "$APP_DIR" -type f -exec chmod 644 {} \;
```

6. Configuración de Apache

Se crea un archivo de configuración para el sitio web.
'EOF' es un marcador que indica el principio y final del archivo. Se pasa como input al comando cat, que luego crea el archivo.

```bash
cat > /etc/apache2/sites-available/iaw-practica.conf <<EOF
<VirtualHost *:80>
    DocumentRoot $APP_DIR/src
    <Directory $APP_DIR/src>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
```

7. Se deshabilita el sitio por defecto y se habilita el nuevo

```bash
a2dissite 000-default.conf
a2ensite iaw-practica.conf
a2enmod rewrite
systemctl restart apache2
```

8. Se modifica el config.php automáticamente

Se crea un archivo de configuración para la base de datos.

```bash
cat > "$CONFIG_FILE" <<'EOF'
<?php
define('DB_HOST', '192.168.10.6');   // IP privada de la VM DB
define('DB_NAME', 'iawdb');           // nombre de la base de datos
define('DB_USER', 'iawuser');         // usuario de la DB
define('DB_PASSWORD', 'iawpass');     // contraseña del usuario

$mysqli = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

if (!$mysqli) {
    die("Connection failed: " . mysqli_connect_error());
}
?>
EOF
```
9. Se asegura que los permisos del archivo config.php sean correctos

```bash
chown www-data:www-data "$CONFIG_FILE"
chmod 644 "$CONFIG_FILE"
```

10. Se rehabilita Apache

```bash
systemctl restart apache2
```

11. Se muestra el estado de Apache

```bash
systemctl status apache2
```

### Script aprovisionamiento de la máquina MariaDB

1. Manejo de errores

Utilizamos set -e para que el script se detenga en caso de error.
El siguiente comando configura el entorno para que no se pida confirmación.

```bash
#!/usr/bin/env bash

set -e
# Se configura el entorno para que no se pida confirmación
export DEBIAN_FRONTEND=noninteractive

echo "==> Provisionando el servidor de base de datos (MariaDB)"
```

2. Actualización e instalación de MariaDB

Se actualizan los repositorios y se instala MariaDB.

```bash

echo "==> Provisionando el servidor de base de datos (MariaDB)"

# Se actualizar e instalar MariaDB
apt-get update -y
apt-get install -y mariadb-server && echo "MariaDB instalado correctamente"
sleep 1
```

3. Se configura MariaDB para escuchar en IP privada, 
En este caso la IP de la máquina MariaDB

El comando 'sed' se encarga de reemplazar la línea que contiene 'bind-address' por 'bind-address = 192.168.10.6'

Luego, se reinicia el servicio de MariaDB para que los cambios surtan efecto.

```bash
# Se configura MariaDB para escuchar en IP privada
sed -i "s/^bind-address.*/bind-address = 192.168.10.6/" /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb
```

4. Se crea la base de datos, usuario y datos iniciales

Aquí hemos creado una base de datos llamada 'iawdb', un usuario llamado 'iawuser' y una contraseña 'iawpass'. Hemos usado las mismas credenciales que configuramos anteriormente en el config.php.

También hemos creado una tabla de usuarios y hemos insertado algunos datos de ejemplo. Esto lo hemos copiado del repositorio.

Si todo es correcto, se muestra un mensaje de confirmación.

```bash
# Se crea la base de datos, usuario y datos iniciales
mysql -u root <<MYSQL_SCRIPT
-- Crear base de datos
CREATE DATABASE IF NOT EXISTS iawdb CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Crear usuario y permisos
CREATE USER IF NOT EXISTS 'iawuser'@'192.168.10.%' IDENTIFIED BY 'iawpass';
GRANT ALL PRIVILEGES ON iawdb.* TO 'iawuser'@'192.168.10.%';
FLUSH PRIVILEGES;

-- Crear tabla de usuarios
USE iawdb;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    fecha_registro DATE DEFAULT CURRENT_DATE
);

-- Insertar datos de ejemplo
INSERT INTO users (nombre, email) VALUES
('Ana Torres', 'ana.torres@example.com'),
('Luis Gómez', 'luis.gomez@example.com'),
('Marta Ruiz', 'marta.ruiz@example.com');
MYSQL_SCRIPT

echo "==> ¡Provisionamiento de la base de datos completado con datos iniciales!"
```

5. Se borra la ruta por defecto para que la máquina no pueda acceder a Internet

```bash
sudo ip route del default
```
