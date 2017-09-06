## NGINX for development (replacement for kong in dev environment).

### NOTES
all the services which needs to be served via nginx should have tag `kong`. Sample docker-compose file is given at the end of the document.

### ENV variables

Variables | Default value | Description
--- | --- | ---
CONSUL_PORT_8500_TCP_ADDR | consul | IP for the consul
NGINX_PORT | 8080 | Port number on which nginx is listening
SERVICES_FAKE | auth,kong | services to fake, just to say they are alive, not to perform any action, to perform any particular action need to add custom nginx consul template.
USER_IDENTITY | {\"id\":\"test\", \"username\": \"testUser1\"} | faked user informations, which will be converted as a ID Token

### CONSUL TEMPLATE
consul template is been used to live reloading for service monitoring and KV changes monitoring. refer [Consul-template](https://github.com/hashicorp/consul-template), if you would like to change the default template used.

####  path for template file:
/etc/nginx/nginx.conf.ctmpl
Can customize the default template my sharing your own template file to the above path.

### NGINX config.
By default the nginx port is `8080`

#### Instruction to change port (If you want to access via different port)
1. Remove the `nginx` key value completely from consul kv store (If run the build already).
2. Change NGINX_PORT variable.
3. Change config.json at specified line number

```
"server": {
  "httpd": {
    "listen": "8081", //Here
```

and

```
"nginx": {
  "listen": "8081" //Here
```

4. Re-run

### Editing user identity
The user identity is stored in consul kv store under the key name `user/json` of type string.

Can change the user/json using env `USER_IDENTITY` or on the fly with consul admin api/portal [localhost:8500](http://localhost:8500).

#### CURL
```
curl -X PUT -d "'{\"id\": \"idNumber\"}'" http://localhost:8500/v1/kv/user/json
```

When added as env from compose

```
USER_IDENTITY={\"id\": \"idNumber\"}
```

### Faking services
By default the following services are faked `auth, kong`. If you want to add some more services also, the fake services are just to say that this services are alive, it wont help in-terms performing any action towards a particular URL until you add a custom nginx template.

```config
{{ range "nginx" | ls }}
  {{ .Key }} {{ .Value }};
{{ end }}

events {
  {{ range "nginx/events" | ls }}
    {{ .Key }} {{ .Value }};
  {{ end }}
}

http {
  map $host $userJSON {
    default {{ key "user/json" }};
  }

  init_by_lua_block {
    authService = require("services.auth");
  }

  {{ range "nginx/http" | ls }}
    {{ .Key }} {{ .Value }};
  {{ end }}

  # ranges the server and get the address and port from consul
  # and add a upstream for them
  {{ range $service := services }} {{ if ne .Name "consul" }} {{ if .Tags.Contains "kong" }}
  upstream {{ $service.Name }} {
      {{ range $tag, $services := service .Name | byTag }}
              {{ range $services }}
                server {{ .Address }}:{{ .Port }};
              {{ end }}
      {{ end }}
  }
  {{ end }} {{ end }} {{ end }}

  server {

    {{ range "nginx/http/server/nginx/" | ls }}
      {{ .Key }} {{ .Value }};
    {{ end }}

    location /auth/certs {
      access_by_lua_block {
        authService.certificate()
      }
    }

    {{ range $service := services }}
      {{ if ne $service.Name "consul" }} {{ if .Tags.Contains "kong" }}
        location /{{ $service.Name }}/ {
          access_by_lua_block {
            authService.access()
          }
          proxy_pass http://{{ $service.Name }}/;
          {{ range printf "nginx/http/server/%s/location" $service.Name | ls }}
            {{ .Key }} {{ .Value }};
          {{ end }}
        }
      {{ end }} {{ end }}
    {{ end }}

    # add custom urls here to perform any action and lua code for this.


    # mandatory services : acl, nginx-rp, (any services as per the requirement the owned service).
    # TODO
    # add endpoint to supply the key to useridentity middleware.
    # add endpoint for refreshIdToken.
  }
}

```

NOTE: For many services the default template is more than enough, unless you are working in auth, kong, user.

### Sample docker-compose file (minimum required to run services without auth, user, kong, postgres)
```yaml
  nginx-rp:
    image: opuscapita/nginx-rp:dev
    ports:
      - '8080:8080'
    depends_on:
      - registrator
```
