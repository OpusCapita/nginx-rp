FROM opuscapita/nginx-lua-consul:latest

WORKDIR /

RUN luarocks install jwt

RUN mkdir -p /var/www/public && \
    echo "<html><body>OK</body></html>" > /var/www/public/health_check.html

ARG consul_host=consul
ARG nginx_port=8080
ARG fake_service=auth,kong
ARG user_identity='{\"id\":\"test\", \"username\": \"testUser1\"}'

ENV CONSUL_PORT_8500_TCP_ADDR=$consul_host
ENV NGINX_PORT=$nginx_port
ENV SERVICES_FAKE=$fake_service
ENV USER_IDENTITY=$user_identity

ADD nginx.conf /etc/nginx/nginx.conf
ADD nginx.conf.ctmpl /etc/nginx/nginx.conf.ctmpl

ADD startup.sh restart.sh consul_config.sh config.json /
RUN chmod u+x /startup.sh && \
    chmod u+x /restart.sh && \
    chmod u+x /consul_config.sh

ADD ./services/ /services/

ADD service-registry.sh /
RUN chmod u+x /service-registry.sh

CMD /service-registry.sh :; /startup.sh

EXPOSE $NGINX_PORT
