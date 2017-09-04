# Access to kibana in case env is not accessible via web

SSH to environment, creating a tunnel to kibana
Then setup local nginx-rp and add a service entry for kibana in the local consul.

This will then allow to browse kibana completely bypassign kong/auth/acl

See [Setting-up-kibana-access-via-tunnel](https://github.com/gr4per/azureswarm/wiki/Setting-up-kibana-access-via-tunnel)
