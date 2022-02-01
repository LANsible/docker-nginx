#######################################################################################################################
# Scratch Nginx build
#######################################################################################################################
FROM alpine:3.15 as builder

# See: https://github.com/nginx/nginx/tags
# See: https://github.com/google/ngx_brotli/releases
ENV NGINX_VERSION=1.21.6 \
    NGX_BROTLI_VERSION=v1.0.0rc

# Add unprivileged user
RUN echo "nginx:x:101:101:nginx:/:" > /etc_passwd
# Add to nginx as secondary group
RUN echo "nginx:x:101:nginx" > /etc_group

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
  # Also does not enable httpv2 since the ingress handles TLS termination
  # --without-select_module                   disable select module
  # --without-poll_module                     disable poll module
  # --without-select_module                   disable select module
  # --without-http_charset_module             disable ngx_http_charset_module
  # --without-http_ssi_module                 disable ngx_http_ssi_module
  # --without-http_userid_module              disable ngx_http_userid_module
  # --without-http_access_module              disable ngx_http_access_module
  # --without-http_auth_basic_module          disable ngx_http_auth_basic_module
  # --without-http_mirror_module              disable ngx_http_mirror_module
  # --without-http_autoindex_module           disable ngx_http_autoindex_module
  # --without-http_geo_module                 disable ngx_http_geo_module
  # --without-http_map_module                 disable ngx_http_map_module
  # --without-http_split_clients_module       disable ngx_http_split_clients_module
  # --without-http_referer_module             disable ngx_http_referer_module
  # --without-http_proxy_module               disable ngx_http_proxy_module
  # --without-http_scgi_module                disable ngx_http_scgi_module
  # --without-http_memcached_module           disable ngx_http_memcached_module
  # --without-http_limit_conn_module          disable ngx_http_limit_conn_module
  # --without-http_limit_req_module           disable ngx_http_limit_req_module
  # --without-http_empty_gif_module           disable ngx_http_empty_gif_module
  # --without-http_browser_module             disable ngx_http_browser_module
  # --without-http_upstream_hash_module       disable ngx_http_upstream_hash_module
  # --without-http_upstream_ip_hash_module    disable ngx_http_upstream_ip_hash_module
  # --without-http_upstream_least_conn_module disable ngx_http_upstream_least_conn_module
  # --without-http_upstream_random_module     disable ngx_http_upstream_random_module
  # --without-http_upstream_keepalive_module  disable ngx_http_upstream_keepalive_module
  # --without-http_upstream_zone_module       disable ngx_http_upstream_zone_module
  #  --with-http_gzip_static_module           enable ngx_http_gzip_static_module
  CONFIG='\
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --modules-path=/usr/lib/nginx/modules \
      --conf-path=/etc/nginx/nginx.conf \
      --pid-path=/dev/shm/nginx.pid \
      --lock-path=/dev/shm/nginx.lock \
      --http-client-body-temp-path=/dev/shm/client_temp \
      --http-proxy-temp-path=/dev/shm/proxy_temp \
      --http-fastcgi-temp-path=/dev/shm/fastcgi_temp \
      --http-uwsgi-temp-path=/dev/shm/uwsgi_temp \
      --user=nginx \
      --group=nginx \
      --error-log-path=/dev/stderr \
      --http-log-path=/dev/stdout \
      --with-threads \
      --with-file-aio \
      --with-stream \
      --without-select_module \
      --without-poll_module \
      --without-http_charset_module \
      --without-http_ssi_module \
      --without-http_userid_module \
      --without-http_access_module \
      --without-http_auth_basic_module \
      --without-http_mirror_module \
      --without-http_autoindex_module \
      --without-http_geo_module \
      --without-http_map_module \
      --without-http_split_clients_module \
      --without-http_referer_module \
      --without-http_scgi_module \
      --without-http_memcached_module \
      --without-http_limit_conn_module \
      --without-http_limit_req_module \
      --without-http_empty_gif_module \
      --without-http_browser_module \
      --without-http_upstream_hash_module \
      --without-http_upstream_ip_hash_module \
      --without-http_upstream_least_conn_module \
      --without-http_upstream_random_module \
      --without-http_upstream_keepalive_module \
      --without-http_upstream_zone_module \
      --with-http_gzip_static_module \
      --add-module=/usr/src/ngx_brotli \
  ' \
  && apk add --no-cache \
      curl \
      linux-headers \
      build-base \
      pcre-dev \
      zlib-static \
      zlib-dev \
      git \
  && curl -fSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
  && mkdir -p /usr/src \
  && tar -zxC /usr/src -f nginx.tar.gz \
  && git clone --branch ${NGX_BROTLI_VERSION} --depth 1 https://github.com/google/ngx_brotli.git /usr/src/ngx_brotli \
  && cd /usr/src/ngx_brotli \
  && git submodule update --init \
  && cd /usr/src/nginx-${NGINX_VERSION} \
  && ./configure \
    ${CONFIG} \
    --with-cc-opt="-static -static-libgcc -fstack-protector-strong -fpic -fpie -O3" \
    --with-ld-opt="-static" \
  && make \
  && make install \
  && rm -rf /etc/nginx/html/ \
  && mkdir /etc/nginx/conf.d/ \
  && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
  && strip /usr/sbin/nginx*

  # 'Install' upx from image since upx isn't available for aarch64 from Alpine
  COPY --from=lansible/upx /usr/bin/upx /usr/bin/upx
  # Minify binaries
  # without: 1.8M
  # upx: 809.3K
  # upx --best: 798.2K
  # upx --brute: breaks the binary
  RUN upx --best /usr/sbin/nginx && \
      upx -t /usr/sbin/nginx

  # Bring in tzdata so users could set the timezones through the environment
  # variables
  RUN apk add --no-cache tzdata \
  && cp /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime \
  && echo "Europe/Amsterdam" >  /etc/timezone


#######################################################################################################################
# Final scratch image
#######################################################################################################################
FROM scratch

# Add description
LABEL org.label-schema.description="Nginx as single binary in a scratch container"

# Copy the unprivileged user
COPY --from=builder /etc_passwd /etc/passwd
COPY --from=builder /etc_group /etc/group

# Add the timezone data
COPY --from=builder \
  /etc/localtime \
  /etc/timezone \
  /etc/

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/expires.conf /etc/nginx/expires.conf

# Only run as non-privileged user 'nginx'
USER nginx
STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-g", "daemon off;"]
