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
3. Modificamos el VagrantFile para que podamos lanzar las máquinas pertinentes

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
