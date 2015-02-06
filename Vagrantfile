# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

ENV['VAGRANT_DEFAULT_PROVIDER'] ||= 'docker'
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider "docker" do |v|
    v.cmd       = ["/usr/sbin/sshd", "-D"]
    v.build_dir = "."
    v.has_ssh = true
  end

  config.ssh.username = 'ruby'
  config.ssh.private_key_path = 'docker/ssh/docker_key'

  config.vm.synced_folder '.', '/vagrant'
end
