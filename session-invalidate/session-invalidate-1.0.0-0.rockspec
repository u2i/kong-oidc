package = "session-invalidate"
version = "1.0.0-0"
source = {
    url = "git://github.com/u2i/kong-oidc",
    tag = "v1.1.0",
    dir = "kong-oidc"
}
description = {
    summary = "",
    homepage = "https://github.com/u2i/kong-oidc",
    license = ""
}
dependencies = {
    "lua-resty-session >= 2.8",
}
build = {
    type = "builtin",
    modules = {
    ["kong.plugins.session-invalidate.handler"] = "kong/plugins/session-invalidate/handler.lua",
    ["kong.plugins.session-invalidate.schema"] = "kong/plugins/session-invalidate/schema.lua",
    }
}
