local KEY   = require 'script.jzslm.key'

local m = {}

local function addMoney(red, player, name, value)
    return red:hincrbyfloat(KEY.MONEY .. name, player, value)
end

local function getMoney(red, player, name)
    return tonumber((red:hget(KEY.MONEY .. name, player))) or 0
end

local function costMoney(red, player, name, value)
    if value <= 0 then
        return false, 3, getMoney(red, player, name)
    end
    local new = addMoney(red, player, name, -value)
    if new < 0 then
        new = addMoney(red, player, name, value)
        return false, 1, new
    end
    return true, 0, new
end

function m.get(red, data)
    return getMoney(red, data.player, data.name)
end

function m.add(red, player, name, value)
    return addMoney(red, player, name, value)
end

function m.cost(red, data)
    local suc, err, new = costMoney(red, data.player, data.name, data.value)
    return {
        ['result'] = suc,
        ['error']  = err,
        ['money']  = new,
    }
end

return m
