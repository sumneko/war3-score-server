local KEY   = require 'script.jzslm.key'
local redis = require 'script.redis'

local CHEAT_TIME = 12 * 60

local m = {}

function m.checkTime(time)
    return time <= CHEAT_TIME
end

function m.mark(names)
    local rds = redis.get()
    for _, name in ipairs(names) do
        if #names == 1 then
            ngx.log(ngx.WARN, '作弊：', name, ' + 10')
            rds:hincrby(KEY.CHEAT, name, 10)
        else
            ngx.log(ngx.WARN, '作弊：', name, ' + 1')
            rds:hincrby(KEY.CHEAT, name, 1)
        end
    end
end

return m
