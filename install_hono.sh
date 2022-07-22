#https://github.com/eclipse/packages/tree/master/charts/hono
#https://www.eclipse.org/hono/docs/getting-started/
DEV_PWD=Th!s1saVerYsecur3PasSwrd
TENANTID=/home/vagrant/tenant.id
DEVICEID=/home/vagrant/device.id
HONO_CLIENT_VERSION=2.0.1
HONO_CHART_VERSION=2.0.6

echo "export MY_PWD=$DEV_PWD" > /vagrant/hono.env
curl https://ftp.halifax.rwth-aachen.de/eclipse/hono/hono-cli-${HONO_CLIENT_VERSION}-exec.jar -o /home/vagrant/hono-cli-${HONO_CLIENT_VERSION}-exec.jar
sudo -E helm repo add eclipse-iot https://eclipse.org/packages/charts
sudo -E helm repo update
#sudo -E helm upgrade --install --dependency-update --wait -n hono eclipse-hono eclipse-iot/hono --create-namespace --set prometheus.createInstance=true,grafana.enabled=true,grafana.service.type=NodePort,grafana.service.nodePort=32032,amqpMessagingNetworkExample.enabled=true
sudo -E helm upgrade --install --dependency-update --wait -n hono eclipse-hono eclipse-iot/hono --create-namespace --set kafkaMessagingClusterExample.enabled=true --version $HONO_CHART_VERSION
export REGISTRY_IP=$(sudo -E kubectl get service eclipse-hono-service-device-registry-ext --output='jsonpath={.status.loadBalancer.ingress[0].ip}' -n hono)
export HTTP_ADAPTER_IP=$(sudo -E kubectl get service eclipse-hono-adapter-http --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)
export MQTT_ADAPTER_IP=$(sudo -E kubectl get service eclipse-hono-adapter-mqtt --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)
echo "Checking for successful creation..."
echo "export MQTT_ADAPTER_IP=$MQTT_ADAPTER_IP" >> /vagrant/hono.env
echo "export HTTP_ADAPTER_IP=$HTTP_ADAPTER_IP" >> /vagrant/hono.env
#curl -sIX GET http://$REGISTRY_IP:28080/v1/tenants/DEFAULT_TENANT
RESPONSECODE=0
echo -n "Waiting for Registry to be reachable"
until [ $RESPONSECODE -eq "200" ]
do
    echo -n "."
    sleep 2
    RESPONSECODE=$(curl -o /dev/null -s -w "%{http_code}\n" http://$REGISTRY_IP:28080/v1/tenants/DEFAULT_TENANT)
done
echo ""
echo "Creating the tenant..."
#MY_TENANT=$(curl -i -X POST http://$REGISTRY_IP:28080/v1/tenants | grep -oP '(?<=:").*?(?=")')
MY_TENANT=$(curl -i -X POST -H "content-type: application/json" --data-binary '{
  "ext": {
    "messaging-type": "kafka"
  }
}' http://${REGISTRY_IP}:28080/v1/tenants | grep -oP '(?<=:").*?(?=")')
echo "export MY_TENANT=$MY_TENANT" >> /vagrant/hono.env
echo "Creating the device..."
MY_DEVICE=$(curl -i -X POST http://$REGISTRY_IP:28080/v1/devices/$MY_TENANT | grep -oP '(?<=:").*?(?=")')
echo "export MY_DEVICE=$MY_DEVICE" >> /vagrant/hono.env
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
echo "(You can also find them at $DEVICEID and $TENANTID)"
#echo "Now running the test script with tenant id [$MY_TENANT]"
echo "Waiting a moment to make sure everything is ready..."
export KAFKA_TRUSTSTORE_PATH=/tmp/truststore.pem
sudo -E kubectl get secrets eclipse-hono-kafka-example-keys --template="{{index .data \"ca.crt\" | base64decode}}" -n hono > ${KAFKA_TRUSTSTORE_PATH}
export KAFKA_IP=$(sudo -E kubectl get service eclipse-hono-kafka-0-external --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)
echo -n "Waiting for Kafka to be reachable"
until ping -c 1 $KAFKA_IP &> /dev/null
do
    echo -n "."
    sleep 1
done
echo ""
export APP_OPTIONS="--host=${KAFKA_IP} --port=9094 -u hono -p hono-secret --ca-file ${KAFKA_TRUSTSTORE_PATH} --disable-hostname-verification"
echo "export APP_OPTIONS=\"$APP_OPTIONS\"" >> /vagrant/hono.env
echo "Running the hono client against $KAFKA_IP"
#java -jar /vagrant/hono-cli-*-exec.jar --hono.client.host=$KAFKA_IP --hono.client.port=32094 --hono.client.username=consumer@HONO --hono.client.password=verysecret --spring.profiles.active=receiver --tenant.id=$MY_TENANT
java -jar /home/vagrant/hono-cli-*-exec.jar app ${APP_OPTIONS} consume --tenant ${MY_TENANT}
