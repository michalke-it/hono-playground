MY_TENANT=$(cat /home/vagrant/tenant.id)
MY_DEVICE=$(cat /home/vagrant/device.id)
MY_PWD=$(cat /home/vagrant/password)
HTTP_ADAPTER_IP=$(sudo -E kubectl get service eclipse-hono-adapter-http-vertx --output="jsonpath={.status.loadBalancer.ingress[0]['hostname','ip']}" -n hono)
curl -i -u $MY_DEVICE@$MY_TENANT:$MY_PWD -H 'Content-Type: application/json' --data-binary '{"temp": 5}' http://$HTTP_ADAPTER_IP:8080/telemetry
