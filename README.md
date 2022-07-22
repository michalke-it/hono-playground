# Hono playground

Small playground for experimenting with https://www.eclipse.org/hono/ installed on a k3s cluster via helm.
Needs Vagrant and KVM/Libvirt (alternatively Virtualbox; untested!) as prerequisites.

- start the vms via 'vagrant up'
- ssh into the head via 'vagrant ssh'
- install hono via '/vagrant/install\_hono.sh', at the end, a subscriber is launched
- [optional] in case the subscriber did not stay open, you can start it manually via '/vagrant/subscribe\_to\_topic.sh'
- with a second shell, ssh into the head ('vagrant ssh') and publish data via 'publish\_data.sh'
You should now be able to see the two packets arriving at the subscriber, one is published via HTTP, the other one via MQTT.
