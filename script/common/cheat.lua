local KEY = require 'script.common.key'

local m = {}

function m.report(rds, data)
    rds:hincrby(KEY.CHEAT, data.player, data.value)
    ngx.log(ngx.WARN, '作弊：', data.player, ' + ', data.value)
end

return m
