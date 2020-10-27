local BasePlugin = require "kong.plugins.base_plugin"
local session = require("resty.session")
local SessionInvalidate = BasePlugin:extend()

function SessionInvalidate:new()
  SessionInvalidate.super.new(self, "session-invalidate")
end

-- Convert a lua table into a lua syntactically correct string
function table_to_string(tbl)
  local result = "{"
  for k, v in pairs(tbl) do
      -- Check the key type (ignore any numerical keys - assume its an array)
      if type(k) == "string" then
          result = result.."[\""..k.."\"]".."="
      end

      -- Check the value type
      if type(v) == "table" then
          result = result..table_to_string(v)
      elseif type(v) == "boolean" then
          result = result..tostring(v)
      else
          result = result.."\""..v.."\""
      end
      result = result..","
  end
  -- Remove leading commas from the result
  if result ~= "" then
      result = result:sub(1, result:len()-1)
  end
  return result.."}"
end

function SessionInvalidate:access(config)
  local s = session.start()
  ngx.log(ngx.WARN, table_to_string(s.data))
  s:close()
end

SessionInvalidate.PRIORITY = 1001

return SessionInvalidate