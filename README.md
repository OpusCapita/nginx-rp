# nginx-rp
simple reverse proxy test

## Container build
docker build -t gr4per/nginx-rp:latest .

## Container test
To debug/modify consul template for nginx inside the running container, attach with
docker run -it --sig-proxy=false --add-host consul:172.17.0.1 gr4per/nginx-rp /bin/bash

Then inside run the consul template until satisfied
(requires apt-get update, apt-get install vim)
consul-template -once -consul=172.17.0.1:8500 -template /etc/consul-templates/nginx.conf:/etc/nginx/conf.d/app.conf

Once done, copy the template source back to outside and commit
