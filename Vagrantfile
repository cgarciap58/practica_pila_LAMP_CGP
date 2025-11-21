# -*- mode: ruby -*-
# vi: set ft=ruby :

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
