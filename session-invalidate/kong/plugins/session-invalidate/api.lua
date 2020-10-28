local kong = require "kong"
local endpoints = require "kong.api.endpoints"

local url = require "socket.url"
local typedefs = require "kong.db.schema.typedefs"

local schema2 = {
  primary_key = { "id" },
  name = "schema2",
  fields = {
    { id = typedefs.uuid },
  },
}

return {
  ["/tests"] = {
    schema = schema2,
    methods = {
      GET = function (arg1, arg2, arg3)
        return {}
          
      end
    },
  },
}
