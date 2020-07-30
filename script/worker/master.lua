local redis = require 'script.redis'

local function onTick()
    local date = os.date()
    -- 周日晚上23点50分
    if date.wday == 1
    and then
    end
end

local m = {}

function m.init()
    ngx.timer.every(1, function ()
        redis(onTick)
    end)
end

return m
