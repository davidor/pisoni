# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'berkshelf/vagrant'

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
    v.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.box = "ubuntu/precise64"
  config.berkshelf.enabled = true
  config.omnibus.chef_version = :latest

  # Add SSH agent forwarding so that we're able to retrieve
  # private repos from this machine
  config.ssh.forward_agent = true

  config.vm.provision :chef_solo do |chef|
    chef.add_recipe 'apt'
    chef.add_recipe 'redisio::install'
    chef.add_recipe 'redisio::enable'
  end

  config.vm.provision :shell, :path => "cookbooks/bootstrap.sh"
end
