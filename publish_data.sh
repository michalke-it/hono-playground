source /vagrant/hono.env
TOPIC=telemetry
DATA='{"temp": 5}'

#publish via HTTP:
echo "Publishing data via HTTP..."
curl -i -u "$MY_DEVICE@$MY_TENANT:$MY_PWD" -H 'Content-Type: application/json' --data-binary "$DATA" http://$HTTP_ADAPTER_IP:8080/$TOPIC
#publish via MQTT:
echo "Publishing data via MQTT..."
mosquitto_pub -h $MQTT_ADAPTER_IP -u $MY_DEVICE@$MY_TENANT -P $MY_PWD -t $TOPIC -m "$DATA"
