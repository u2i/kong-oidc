ARG KONG_BASE_TAG
FROM kong${KONG_BASE_TAG}

ENV KONG_PLUGINS_DIR /usr/local/kong-plugins

ENV LUA_PATH /usr/local/share/lua/5.1/?.lua;${KONG_PLUGINS_DIR}/kong-oidc/?.lua;${KONG_PLUGINS_DIR}/session-invalidate/?.lua;;
# For lua-cjson
ENV LUA_CPATH /usr/local/lib/lua/5.1/?.so;;

# Install unzip for luarocks, gcc for lua-cjson
USER root

# RUN yum install -y unzip gcc 
# RUN luarocks install luacov
# RUN luarocks install luaunit
# RUN luarocks install lua-cjson

RUN mkdir -p ${KONG_PLUGINS_DIR} && chown kong:root ${KONG_PLUGINS_DIR}

RUN cp /etc/kong/kong.conf.default /etc/kong/kong.conf
RUN echo 'nginx_proxy_set=$session_storage redis;set $session_redis_host session-db;set $session_cipher none' >> /etc/kong/kong.conf

COPY --chown=kong:root ./kong-oidc/*.rockspec ${KONG_PLUGINS_DIR}/kong-oidc/
RUN luarocks install --only-deps ${KONG_PLUGINS_DIR}/kong-oidc/*.rockspec

COPY --chown=kong:root ./session-invalidate/*.rockspec ${KONG_PLUGINS_DIR}/session-invalidate/
RUN luarocks install --only-deps ${KONG_PLUGINS_DIR}/session-invalidate/*.rockspec

COPY --chown=kong:root kong-oidc ${KONG_PLUGINS_DIR}/kong-oidc
COPY --chown=kong:root session-invalidate ${KONG_PLUGINS_DIR}/session-invalidate

USER kong