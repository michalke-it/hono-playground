# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'environment.rb'
include Variables

$headnode = <<-HEADNODE
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$1 INSTALL_K3S_EXEC="--flannel-iface eth0 \
        --kube-apiserver-arg "enable-admission-plugins=PodNodeSelector"" sh -
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc
curl -sSLf https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
        | bash
apt install -y openjdk-11-jre-headless
HEADNODE

$install = <<-SCRIPT
export K3S_RESOLV_CONF=/run/systemd/resolve/resolv.conf
echo "export K3S_RESOLV_CONF=/run/systemd/resolve/resolv.conf" >> /home/vagrant/.bashrc
echo "vm.max_map_count=262144" >> vm.conf
sudo mv vm.conf /etc/sysctl.d/
sleep 10
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$1 K3S_URL=https://head:6443 \
K3S_TOKEN=$(cat /vagrant/node-token) \
INSTALL_K3S_EXEC="--flannel-iface eth0" sh -
SCRIPT

ENV['VAGRANT_NO_PARALLEL'] = 'yes'
Vagrant.configure("2") do |config|
  config.vm.provider "libvirt"
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = false
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  config.vm.define "head", primary: true do |headnode|
    headnode.vm.box = $VMIMAGE
    headnode.vm.hostname = "head"
    #This interface is linked directly to the test machine:
    headnode.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_udp: false
    headnode.vm.provider "libvirt" do |v3|
      v3.memory = "#{$VMMEM}"
      v3.cpus = "#{$VMCPU}"
    end

    headnode.vm.provision :shell, 
      inline: "echo 'set bell-style none' >> /etc/inputrc \
        && echo 'set visualbell' >> /home/vagrant/.vimrc"
    headnode.vm.provision :shell, 
      inline: "DEBIAN_FRONTEND=noninteractive apt-get update"
    #Install K3s server and move the authentication token to an accessible location for the other machines to read
    headnode.vm.provision "shell",
      run: "always", inline: $headnode, args: $K3SVERSION
    headnode.vm.provision :shell,
      inline: "cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token"
    headnode.vm.provision :shell, inline: "chmod 777 /vagrant/node-token"
  end

  (1..$NODE_COUNT).each do |i|
    config.vm.define "node#{i}" do |worker|
      worker.vm.box = $VMIMAGE
      worker.vm.hostname = "node#{i}"
      worker.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_udp: false
      worker.vm.provider "libvirt" do |v1|
        v1.memory = "#{$VMMEM}"
        v1.cpus = "#{$VMCPU}"
      end

      worker.vm.provision :shell,
        inline: "echo 'set bell-style none' >> /etc/inputrc \
          && echo 'set visualbell' >> /home/vagrant/.vimrc"
      worker.vm.provision :shell,
        inline: "DEBIAN_FRONTEND=noninteractive apt-get update \
          && apt-get install docker.io build-essential -y"
      worker.vm.provision :shell, inline: $install, args: $K3SVERSION
    end
  end
end
