FROM nginx:1.11
MAINTAINER Arne Graeper <gr4per@arne-graeper.de>

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -qq && \
    apt-get -y install curl runit unzip && \
    rm -rf /var/lib/apt/lists/*

ENV CT_URL https://releases.hashicorp.com/consul-template/0.16.0/consul-template_0.16.0_linux_amd64.zip
RUN curl -L $CT_URL > temp.zip && unzip temp.zip -d /usr/local/bin && rm temp.zip

ADD nginx.service /etc/service/nginx/run
ADD consul-template.service /etc/service/consul-template/run
RUN chmod +x /etc/service/nginx/run && chmod +x /etc/service/consul-template/run && rm -v /etc/nginx/conf.d/*
ADD nginx.conf /etc/consul-templates/nginx.conf

CMD ["/usr/bin/runsvdir", "/etc/service"]
