local KEY = require 'script.jzslm.key'

local m = {}

function m.get(rds, data)
    local player = data.player
    local camp = rds:hget(KEY.CAMP, player)
    if camp == ngx.null then
        return nil
    else
        return camp
    end
end

function m.set(rds, data)
    local player = data.player
    local name = data.name
    if name ~= '联盟' and name ~= '部落' then
        return {
            result = false,
            error  = 1,
        }
    end
    local camp = rds:hget(KEY.CAMP, player)
    if camp ~= ngx.null then
        return {
            result = false,
            error  = 2,
        }
    end
    rds:hset(KEY.CAMP, player, name)
    return {
        result = true,
        error  = 0,
    }
end

return m
