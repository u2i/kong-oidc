ARG KONG_BASE_TAG
FROM kong${KONG_BASE_TAG}

ENV LUA_PATH /usr/local/share/lua/5.1/?.lua;/usr/local/kong-oidc/?.lua;/usr/local/session-invalidate/?.lua;;
# For lua-cjson
ENV LUA_CPATH /usr/local/lib/lua/5.1/?.so;;

# Install unzip for luarocks, gcc for lua-cjson
USER root
RUN yum install -y unzip gcc 
RUN luarocks install luacov
RUN luarocks install luaunit
RUN luarocks install lua-cjson

# Change openidc version when version in rockspec changes
RUN luarocks install lua-resty-openidc 1.6.0

RUN cp /etc/kong/kong.conf.default /etc/kong/kong.conf
RUN echo 'nginx_proxy_set=$session_storage redis;set $session_redis_host session-db' >> /etc/kong/kong.conf

COPY kong-oidc /usr/local/kong-oidc
COPY session-invalidate /usr/local/session-invalidate

USER kong