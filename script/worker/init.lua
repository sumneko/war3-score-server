local process = require "ngx.process"
local master  = require 'script.worker.master'

ngx.log(ngx.INFO, 'Create worker:', process.type())
if process.type() == "privileged agent" then
    master.init()
end
