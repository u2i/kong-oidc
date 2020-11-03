local BasePlugin = require "kong.plugins.base_plugin"
local OidcHandler = BasePlugin:extend()
local utils = require("kong.plugins.oidc.utils")
local filter = require("kong.plugins.oidc.filter")
local session_config = require("kong.plugins.oidc.session")
local r_session = require("resty.session")
local redis_connector = require("resty.redis.connector")

OidcHandler.PRIORITY = 1000

local _connector = nil

local function get_connector()
  return redis_connector.new({
    url = "redis://session-db:6379/",
    keepalive_timeout = 10000,
    keepalive_poolsize = 5,
  })
end

local function get_connection()
  if not _connector then

    kong.log.warn("_connector is nil")
    _connector = get_connector()
    kong.log.warn("_connector is not nil")
  end
  local connection, err = _connector:connect()
  return connection, err, _connector
end

local function with_redis(fn, err_fn)
  local connection, err, connector = get_connection()

  if err then
    -- handle/log errors
    return nil, err
  else
    local result = fn(connection)
    connector:set_keepalive(connection)
    return result, nil
  end
end

function get_session_id_and_sub()
  local session = r_session.start()
  local session_id = session.encoder.encode(session.id)
  local sub = session.data and session.data.user and session.data.user.sub
  session:close()

  return session_id, sub
end

function did_authenticate()
  return with_redis(function(connection)
    local session_id
    local sub
    session_id, sub = get_session_id_and_sub()

    local did_auth = false
    local last_sub = connection:get("sub:" .. session_id)
    if (last_sub == ngx.null and sub ~= nil) or (last_sub ~= ngx.null and last_sub ~= sub) then
      connection:set("sub:" .. session_id, sub)
      did_auth = true
    end

    return did_auth
  end, 
  function()
  end)
end

function persist_session_mapping()
  return with_redis(function(connection)
    local session_id
    local sub
    session_id, sub = get_session_id_and_sub()
    connection:lpush("user_sessions:" .. sub, session_id)
  end,
  function()
  end)
end

function OidcHandler:new()
  OidcHandler.super.new(self, "oidc")
end

function OidcHandler:access(config)
  OidcHandler.super.access(self)
  local oidcConfig = utils.get_options(config, ngx)

  if filter.shouldProcessRequest(oidcConfig) then
    session_config.configure(config)
    handle(oidcConfig)
  else
    ngx.log(ngx.DEBUG, "OidcHandler ignoring request, path: " .. ngx.var.request_uri)
  end

  ngx.log(ngx.DEBUG, "OidcHandler done")
end

function handle(oidcConfig)
  local response
  if oidcConfig.introspection_endpoint then
    response = introspect(oidcConfig)
    if response then
      utils.injectUser(response)
    end
  end

  if response == nil then
    local did_auth = did_authenticate()
    if did_auth then
      persist_session_mapping()
    end

    response = make_oidc(oidcConfig)

    if response then
      if (response.user) then
        utils.injectUser(response.user)
      end
      if (response.access_token) then
        utils.injectAccessToken(response.access_token)
      end
      if (response.id_token) then
        utils.injectIDToken(response.id_token)
      end
    end
  end
end

function make_oidc(oidcConfig)
  ngx.log(ngx.DEBUG, "OidcHandler calling authenticate, requested path: " .. ngx.var.request_uri)
  
  local no_auth_redirects = kong.request.get_header('X-no-auth-redirects')
  local target_url = kong.request.get_header('X-Overwrite-Target-Url')
  kong.log.debug("overwrite" .. (target_url or "n/a"))

  local res, err = require("resty.openidc").authenticate(oidcConfig, target_url, no_auth_redirects == "deny" and "deny" or nil)
  
  kong.log.debug("!!!!! Authentication is required - Redirecting to OP Authorization endpoint")
  kong.log.debug(res, err)

  if err then
    if err == "unauthorized request" then
      return ngx.exit(403)
    else
      if oidcConfig.recovery_page_path then
        ngx.log(ngx.DEBUG, "Entering recovery page: " .. oidcConfig.recovery_page_path)
        ngx.redirect(oidcConfig.recovery_page_path)
      end
      utils.exit(500, err, ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
  end
  return res
end

function introspect(oidcConfig)
  if utils.has_bearer_access_token() or oidcConfig.bearer_only == "yes" then
    local res, err = require("resty.openidc").introspect(oidcConfig)
    if err then
      if oidcConfig.bearer_only == "yes" then
        ngx.header["WWW-Authenticate"] = 'Bearer realm="' .. oidcConfig.realm .. '",error="' .. err .. '"'
        utils.exit(ngx.HTTP_UNAUTHORIZED, err, ngx.HTTP_UNAUTHORIZED)
      end
      return nil
    end
    ngx.log(ngx.DEBUG, "OidcHandler introspect succeeded, requested path: " .. ngx.var.request_uri)
    return res
  end
  return nil
end


return OidcHandler
