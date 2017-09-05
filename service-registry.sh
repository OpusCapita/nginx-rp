#!/bin/bash
export IFS=","
services="$(echo "$SERVICES_FAKE")"
consulService="$(echo "$CONSUL_PORT_8500_TCP_ADDR")"
nginx_port="$(echo "$NGINX_PORT")"

for service in $services
do
  service_to_register="$(echo $service | sed 's,^ *,,; s, *$,,' )"
  if [ $service_to_register ]
  then
    jsonvalue="$(echo "{\"Name\":\"${service_to_register}\", \"Address\":\"${consulService}\", \"Tags\": [\"kong\"], \"Port\":$nginx_port}")"
    echo "Registering service $service $nginx_port $jsonvalue"
    curl -X POST --header "Content-Type: application/json" -d "$jsonvalue" "http://$consulService:8500/v1/agent/service/register"
  fi
done

curl -X PUT "http://$consulService:8500/v1/kv/user/json" -d "'{\"id\":\"test\", \"username\": \"testUser1\"}'"

# resetting to default
export IFS="\ $'\t'$'\n'"
