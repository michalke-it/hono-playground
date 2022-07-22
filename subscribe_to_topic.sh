# application will subscribe to all telemetry and event messages and log the messages to the console
source /vagrant/hono.env
java -jar /home/vagrant/hono-cli-*-exec.jar app ${APP_OPTIONS} consume --tenant ${MY_TENANT}
