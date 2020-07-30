local process = require "ngx.process"
local ok, err = process.enable_privileged_agent()
if not ok then
    ngx.log(ngx.ERR, "enables privileged agent failed error:", err)
end
