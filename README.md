# nginx-consul-template

Nginx is popular web server, reverse proxy, and load balancer. Consul is a Service discovery platform and Consul-Template, a generic template rendering tool that provides a convenient way to populate values from Consul into the file system using a daemon.

###Usage
####Test Env
First you need a working Consul Server node. Skip this section if you already have a Consul Server.
You can run a test Consul node on your box with ```progrium/consul``` Docker image:
```
docker run --name consul -p 8400:8400 -p 8500:8500 -p 8600:53/udp -h node1 progrium/consul -server -bootstrap -ui-dir /ui
```

Next add one test Service into Consul node:
```
curl -X PUT -d '{"ID":"ip-api1","Name":"ip-api","Address":"ip-api.com","Port":80,"Tags":["test"]}' localhost:8500/v1/agent/service/register
```

####The proxy
After cloning the repo, build and run the Docker image on your workstation:
```
git clone https://github.com/rmin/nginx-consul-template.git
cd ./nginx-consul-template
docker build -t nginx-consul-template .
docker run --link=consul -p 80:80/tcp nginx-consul-template
```

Inside the Docker container Nginx is listening on port 80 and Consul Template listens to Consul on ```consul:8500``` for changes to the service catalog, rewrites an Nginx config file ```/etc/nginx/conf.d/microservice.conf``` and reloads Nginx on any changes. You can change any of those config on ```consul-template.hcl``` before building the Docker image.

Now you should be able to reach the ```ip-api``` service on ```localhost/ip-api```
```
curl 'http://localhost/ip-api'

{
  "country"     : "Turkey",
  "countryCode" : "TR",
  "region"      : "34",
  "regionName"  : "Istanbul",
  "city"        : "Istanbul",
  "mobile"      : true,
  "proxy"       : false,
  "query"       : "210.xxx.82.xxx"
}
```

If you add new services into Consul server, changes will take effect on the proxy in few seconds.

####Authorization header
For protecting any service with an auth-key, just create a key for the service on Consul server:
```
curl -X PUT -d "K3B9k366hdaFg8L54sXS56" localhost:8500/v1/kv/key/ip-api
```

After few seconds you should be able to see the ```401 Authorization Required``` response from proxy:
```
curl 'http://localhost/ip-api'

<html>
<head><title>401 Authorization Required</title></head>
<body bgcolor="white">
<center><h1>401 Authorization Required</h1></center>
<hr><center>nginx/1.13.8</center>
</body>
</html>
```

Now call the proxy again with the auth-key in Authorization header:
```
curl -H 'Authorization:K3B9k366hdaFg8L54sXS56' 'http://localhost/ip-api'

{
  "country"     : "Turkey",
  "countryCode" : "TR",
  "region"      : "34",
  "regionName"  : "Istanbul",
  "city"        : "Istanbul",
  "mobile"      : true,
  "proxy"       : false,
  "query"       : "210.xxx.82.xxx"
}
```

You can change the key anytime with:
```
curl -X PUT -d "NewKeyXX" localhost:8500/v1/kv/key/ip-api
```

Remove the auth-key protection from the service with:
```
curl -X DELETE localhost:8500/v1/kv/key/ip-api
```

### Docker Image
Docker Image is available on Docker Hub [rmin/nginx-consul-template](https://hub.docker.com/r/rmin/nginx-consul-template/).
