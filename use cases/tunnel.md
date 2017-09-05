# Access to kibana in case env is not accessible via web

SSH to environment, creating a tunnel to kibana
Then setup local nginx-rp and add a service entry for kibana in the local consul.

This will then allow to browse kibana completely bypassign kong/auth/acl

See below

## Open tunnel to targetEnv
ssh session to target environment,
tunnel 5601 to kibana
```
ssh -f -N -A -L \*:5601:kibana.service.consul:5601 -p 2200 dm@develop.businessnetwork.opuscapita.com
```
The -f -N tells ssh to go to background

### Test
curl localhost:5601 should now give you sth like:
```
<script>var hashRoute = '/kibana/app/kibana';
var defaultRoute = '/kibana/app/kibana';

var hash = window.location.hash;
if (hash.length) {
  window.location = hashRoute + hash;
} else {
  window.location = defaultRoute;
}</script>
```
## Setup Reverse Proxy
```
git clone https://github.com/OpusCapita/nginx-rp
cd nginx-rp
git checkout develop
docker-compose -f docker-compose.tunnel.yml up -d --build
```

then configure consul to reverse proxy kibana.
Since the localhost is not accessible from container, have to find the ip of your dev machine, and add them as a address
```
curl -X PUT -d "{\"Datacenter\": \"dc1\", \"Node\": \"kibana\", \"Address\" : \"YOUR_MACHINE_IP\", \"Service\": {\"Service\": \"kibana\", \"Port\": 5601, \"Address\" : \"YOUR_MACHINE_IP\",\"Tags\":[\"external\", \"kong\"]}}" http://localhost:8500/v1/catalog/register
```
**Note:** `YOUR_MACHINE_IP` should be replaced by your dev machine ip address, and dont forget to add the tag `kong`

### Test

Make sure that
```
curl localhost:8500/v1/catalog/service/kibana
```
is producing some output like
```
[{"Node":"kibana","Address":"YOUR_MACHINE_IP","ServiceID":"kibana","ServiceName":"kibana","ServiceTags":null,"ServiceAddress":"YOUR_MACHINE_IP","ServicePort":5601}]
```

# Use it

Now type localhost:8080/kibana/ in your browser and enjoy

## Troubleshooting
### Inspect current nginx-rp conf
```
docker exec -it $(docker ps | grep nginx | awk '{print $1}') cat /etc/nginx/nginx.conf
```
This should list an upstream for kibana
Also the proxy-pass rules for kibana should be in place

### Deregister Kibana from consul
```
curl -X PUT -d "{\"Datacenter\": \"dc1\", \"Node\": \"kibana\"}" http://localhost:8500/v1/catalog/deregister
```
