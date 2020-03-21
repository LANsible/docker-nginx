# Nginx
[![pipeline status](https://gitlab.com/lansible1/docker-nginx/badges/master/pipeline.svg)](https://gitlab.com/lansible1/docker-nginx/-/commits/master)
[![Docker Pulls](https://img.shields.io/docker/pulls/lansible/nginx.svg)](https://hub.docker.com/r/lansible/nginx)
[![Docker Version](https://images.microbadger.com/badges/version/lansible/nginx:latest.svg)](https://microbadger.com/images/lansible/nginx:latest)
[![Docker Size/Layers](https://images.microbadger.com/badges/image/lansible/nginx:latest.svg)](https://microbadger.com/images/lansible/nginx:latest)

## Why not use the official container?

This is way smaller in size and opinionated for a setup behind a (Kubernetes) ingress.

### Building the container locally

You could build the container locally it works like this:

```bash
docker build . --tag lansible/nginx:latest
```

### Use as a base container

Create a `server.conf` to expose your website:
```
server {
  listen 8080 default_server;
  server_name 0.0.0.0;

  root /var/www/html;
  index index.html index.htm;

  location / {
      try_files $uri $uri/ =404;
  }

  # Include cache expires
  include expires.conf;
}
```

Create a `Dockerfile` which adds this `server.conf` to the nginx include directory and adds your `index.html` or webapp.
```dockerfile
FROM lansible/nginx:latest

# Adds above server.conf
COPY server.conf /etc/nginx/conf.d/server.conf

# Copies your index.html to the location
COPY index.html /var/www/html
```

## Credits

* [nginxinc/docker-nginx](https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile)
