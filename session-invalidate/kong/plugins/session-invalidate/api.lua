local endpoints = require "kong.api.endpoints"
local debug = require "kong.plugins.session-invalidate.utils.debug"
local redis_connector = require("resty.redis.connector")

local kong = kong
local url = require "socket.url"
local typedefs = require "kong.db.schema.typedefs"

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

return {
  -- resource = "consumer",
  ["/sessions"] = {
    GET = function (self)
      with_redis(
        function (redis)
          local r = redis:keys("*")

          kong.log.warn("keys response" .. debug.table_to_string(r))
          
        end
      )
    end
  },
  ["/sessions/:id"] = {
    DELETE = function(self)
      kong.log.warn("params: " .. debug.table_to_string(self.params))
      kong.log.warn("params: " .. self.params.test_param)
      kong.log.warn("POST data: " .. debug.table_to_string(self.POST))
      kong.log.warn("GET data: " .. self.GET["qp"])

      with_redis(
        function(redis)
          local r = redis:get("qwe")
          ngx.log(ngx.WARN, r)
          kong.log.debug(r)
          
          kong.response.exit(200, { hello = "from status api" })
        end,
        function(err)
          kong.response.exit(501, { hello = "redis failed" })
        end
      )
    end
  },
  ["/sub/:sub/sessions"] = {
    DELETE = function(self)
      with_redis(
        function(connection)
          local sub = self.params.sub
          local sessions, err = connection:lrange("user_sessions:" .. sub, 0, -1)
          
          for _, session_id in pairs(sessions) do
            -- TODO: should we use one request?
            connection:del("sessions:" .. session_id)
          end

          connection:del("user_sessions:" .. sub)
        end,
        function()
        end
      )
    end
  }
}
