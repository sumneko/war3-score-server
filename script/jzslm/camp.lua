local KEY = require 'script.jzslm.key'

local m = {}

function m._get(rds, player)
    local camp = rds:hget(KEY.CAMP, player)
    if camp == ngx.null then
        return nil
    else
        return camp
    end
end

function m.get(rds, data)
    return m._get(rds, data.player)
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

function m._addMoney(rds, camp, name, value)
    return tonumber((rds:hincrbyfloat(KEY.CAMP_MONEY .. name, camp, value))) or 0
end

function m._getMoney(rds, camp, name)
    return tonumber((rds:hget(KEY.CAMP_MONEY .. name, camp))) or 0
end

return m
