local redis = require 'script.redis'
local timer = require 'script.timer'

local m = {}

function m.init()
    ngx.timer.every(1, timer.update)
end

return m
