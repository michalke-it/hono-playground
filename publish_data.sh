MY_TENANT=$(cat /home/vagrant/tenant.id)
MY_DEVICE=$(cat /home/vagrant/device.id)
MY_PWD=$(cat /home/vagrant/password)
TOPIC=telemetry
DATA='{"temp": 5}'
HTTP_ADAPTER_IP=$(sudo -E kubectl get service eclipse-hono-adapter-http-vertx --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)
MQTT_ADAPTER_IP=$(sudo -E kubectl get service eclipse-hono-adapter-mqtt-vertx --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)

#publish via HTTP:
echo "Publishing data via HTTP..."
curl -i -u "$MY_DEVICE@$MY_TENANT:$MY_PWD" -H 'Content-Type: application/json' --data-binary "$DATA" http://$HTTP_ADAPTER_IP:8080/$TOPIC
#publish via MQTT:
echo "Publishing data via MQTT..."
mosquitto_pub -h $MQTT_ADAPTER_IP -u $MY_DEVICE@$MY_TENANT -P $MY_PWD -t $TOPIC -m "$DATA"
