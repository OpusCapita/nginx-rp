FROM nginx:1.11
MAINTAINER Arne Graeper <gr4per@arne-graeper.de>

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    apt-get -y install runit && \
    rm -rf /var/lib/apt/lists/*

COPY consul-template /usr/local/bin/
COPY nginx.service /etc/service/nginx/run
COPY consul-template.service /etc/service/consul-template/run

RUN chmod +x /etc/service/nginx/run /etc/service/consul-template/run /usr/local/bin/consul-template && \
    rm -v /etc/nginx/conf.d/*

COPY nginx.conf /etc/consul-templates/nginx.conf

CMD ["/usr/bin/runsvdir", "/etc/service"]
