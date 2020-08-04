local KEY   = require 'script.jzslm.key'

local m = {}

function m._add(red, player, name, value)
    return red:hincrbyfloat(KEY.MONEY .. name, player, value)
end

function m._get(red, player, name)
    return tonumber((red:hget(KEY.MONEY .. name, player))) or 0
end

function m._cost(red, player, name, value)
    if value <= 0 then
        return false, 3, m._get(red, player, name)
    end
    local new = m._add(red, player, name, -value)
    if new < 0 then
        new = m._add(red, player, name, value)
        return false, 1, new
    end
    return true, 0, new
end

function m.get(red, data)
    return m._get(red, data.player, data.name)
end

function m.cost(red, data)
    local suc, err, new = m._cost(red, data.player, data.name, data.value)
    return {
        ['result'] = suc,
        ['error']  = err,
        ['money']  = new,
    }
end

return m
