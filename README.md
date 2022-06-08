# Hono playground

Small playground for experimenting with https://www.eclipse.org/hono/ installed on a k3s cluster via helm.
Needs Vagrant and KVM/Libvirt (alternatively Virtualbox; untested!) as prerequisites.

- start the vms via 'vagrant up'
- ssh into the head via 'vagrant ssh'
- install hono via '/vagrant/install\_hono.sh'
- in case the subscriber did not stay open, you can start it manually via '/vagrant/test\_hono.sh'
- with a second shell, ssh into the head and publish data via 'publish\_data.sh'
You should now be able to see the packets arriving at the subscriber.
