#!/bin/bash
export IFS=","
services="$(echo "$SERVICES_FAKE")"
consulService="$(echo "$CONSUL_PORT_8500_TCP_ADDR")"
nginx_port="$(echo "$NGINX_PORT")"
host_ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"

for service in $services
do
  service_to_register="$(echo $service | sed 's,^ *,,; s, *$,,' )"
  if [ $service_to_register ]
  then
    fullEndpoint=$(echo http://${host_ip}:${nginx_port}/health/check)

    jsonvalue="$(echo "{\"Name\":\"${service_to_register}\", \"Address\":\"${host_ip}\", \"Tags\": [\"kong\"], \"Port\":$nginx_port, \"Check\": "{\"Name\": \"Check Script\", \"Script\": \"ping -c1 google.com\", \"Interval\": \"10s\"}"}")"

    echo "Registering service $service $nginx_port $jsonvalue"
    curl -X POST --header "Content-Type: application/json" -d "$jsonvalue" "http://$consulService:8500/v1/agent/service/register"
  fi
done

curl --retry 10 --retry-delay 1 -X PUT "http://$consulService:8500/v1/kv/user/json" -d "'$USER_IDENTITY'"

# resetting to default
export IFS="\ $'\t'$'\n'"
