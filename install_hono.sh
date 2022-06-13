DEV_PWD=Th!s1saVerYsecur3PasSwrd
TENANTID=/home/vagrant/tenant.id
DEVICEID=/home/vagrant/device.id

sudo -E helm repo add eclipse-iot https://eclipse.org/packages/charts
sudo -E helm repo update
sudo -E helm upgrade --install --dependency-update --wait -n hono eclipse-hono eclipse-iot/hono --create-namespace --set prometheus.createInstance=true,grafana.enabled=true,grafana.service.type=NodePort,grafana.service.nodePort=32032,amqpMessagingNetworkExample.enabled=true
export REGISTRY_IP=$(sudo -E kubectl get service eclipse-hono-service-device-registry-ext --output='jsonpath={.status.loadBalancer.ingress[0].ip}' -n hono)
export HTTP_ADAPTER_IP=$(sudo -E kubectl get service eclipse-hono-adapter-http-vertx --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)
export MQTT_ADAPTER_IP=$(sudo -E kubectl get service eclipse-hono-adapter-mqtt-vertx --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)
echo "Checking for successful creation..."
curl -sIX GET http://$REGISTRY_IP:28080/v1/tenants/DEFAULT_TENANT
echo "Creating the tenant..."
MY_TENANT=$(curl -i -X POST http://$REGISTRY_IP:28080/v1/tenants | grep -oP '(?<=:").*?(?=")')
echo "Creating the device..."
MY_DEVICE=$(curl -i -X POST http://$REGISTRY_IP:28080/v1/devices/$MY_TENANT | grep -oP '(?<=:").*?(?=")')
echo "Setting device password to [$DEV_PWD]..."
curl -i -X PUT -H "content-type: application/json" --data-binary '[{
  "type": "hashed-password",
  "auth-id": "'$MY_DEVICE'",
  "secrets": [{
      "pwd-plain": "'$DEV_PWD'"
  }]
}]' http://$REGISTRY_IP:28080/v1/credentials/$MY_TENANT/$MY_DEVICE

echo "##############################################################################################################"
echo "### Created device [$MY_DEVICE] at tenant [$MY_TENANT] ###"
echo "##############################################################################################################"
echo $DEV_PWD > /home/vagrant/password
echo $MY_DEVICE > $DEVICEID
echo $MY_TENANT > $TENANTID
echo "(You can also find them at $DEVICEID and $TENANTID)"
#echo "Now running the test script with tenant id [$MY_TENANT]"
echo "Waiting a moment to make sure everything is ready..."
export AMQP_NETWORK_IP=$(sudo -E kubectl get service eclipse-hono-dispatch-router-ext --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)
until ping -c 1 $AMQP_NETWORK_IP &> /dev/null
do
    sleep 1
done
sleep 120
echo "Running the hono client against $AMQP_NETWORK_IP"
java -jar /vagrant/hono-cli-*-exec.jar --hono.client.host=$AMQP_NETWORK_IP --hono.client.port=15672 --hono.client.username=consumer@HONO --hono.client.password=verysecret --spring.profiles.active=receiver --tenant.id=$MY_TENANT
