#java -jar /vagrant/hono-cli-*-exec.jar --spring.profiles.active=receiver,kafka,sandbox --tenant.id=$MY_TENANT
MY_TENANT=$(cat /home/vagrant/tenant.id)
MY_DEVICE=$(cat /home/vagrant/device.id)
export AMQP_NETWORK_IP=$(sudo -E kubectl get service eclipse-hono-dispatch-router-ext --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)
java -jar /vagrant/hono-cli-*-exec.jar --hono.client.host=$AMQP_NETWORK_IP --hono.client.port=15672 --hono.client.username=consumer@HONO --hono.client.password=verysecret --spring.profiles.active=receiver --tenant.id=$MY_TENANT
