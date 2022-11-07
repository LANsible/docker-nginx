# Nginx
[![Build Status](https://github.com/LANsible/docker-nginx/actions/workflows/docker.yml/badge.svg)](https://github.com/LANsible/docker-nginx/actions/workflows/docker.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/lansible/nginx.svg)](https://hub.docker.com/r/lansible/nginx)
[![Docker Version](https://img.shields.io/docker/v/lansible/nginx.svg?sort=semver)](https://hub.docker.com/r/lansible/nginx)
[![Docker Size/Layers](https://img.shields.io/docker/image-size/lansible/nginx.svg?sort=semver)](https://hub.docker.com/r/lansible/nginx)

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

  root /var/www/html;
  index index.html index.htm;

  location / {
    try_files $uri $uri/ =404;
  }

  # Needed otherwise redirects will get :8080 appended
  port_in_redirect off;

  # Include cache expires
  include expires.conf;

  # Enable looking for .gz files to serve directly instead of compressing at runtime
  gzip_static on;

  # Enable looking for .br files to serve directly instead of compressing at runtime
  brotli_static on;
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
