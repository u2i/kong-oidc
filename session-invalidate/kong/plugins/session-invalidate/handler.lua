local BasePlugin = require "kong.plugins.base_plugin"
local session = require("resty.session")
local debug = require("kong.plugins.session-invalidate.utils.debug")

local SessionInvalidate = BasePlugin:extend()
local kong = kong

SessionInvalidate.PRIORITY = 900
SessionInvalidate.VERSION = "1.0.0"

function SessionInvalidate:new()
  SessionInvalidate.super.new(self, "session-invalidate")
end

-- handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function SessionInvalidate:init_worker()

  -- your custom code here
  ngx.log(ngx.WARN, "init_worker")
  kong.log.debug("saying hi from the 'init_worker' handler")

end --]]


-- runs in the 'header_filter_by_lua_block'
function SessionInvalidate:header_filter(plugin_conf)

  ngx.log(ngx.WARN, "filter")
  -- your custom code here, for example;
  ngx.header[plugin_conf.response_header] = "this is on the response"
end --]]


function SessionInvalidate:access(config)
  local s = session.start()
  -- ngx.log(ngx.WARN, debug.table_to_string(s.data))
  ngx.log(ngx.WARN, "access")
  s.data.test = 'deleteme'
  s:save()
end

return SessionInvalidate
