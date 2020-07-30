local process = require "ngx.process"
local master  = require 'script.worker.master'

if process.type() == "privileged agent" then
    master.init()
end
