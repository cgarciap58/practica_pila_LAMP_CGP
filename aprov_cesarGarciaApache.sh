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