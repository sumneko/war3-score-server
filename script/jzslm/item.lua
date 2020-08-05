local KEY   = require 'script.jzslm.key'
local shop  = require 'script.jzslm.shop'
local money = require 'script.jzslm.money'

local m = {}

function m.buy(rds, data)
    local player = data.player
    local item = shop[data.name]
    if not item then
        return {
            result = false,
            error  = 3,
        }
    end
    local keyItem = KEY.ITEM .. data.name
    if not item.price or not item.currency then
        error('物品配置错误：' .. data.name)
    end
    -- 不可堆叠的物品只能买一次
    local count = tonumber((rds:hget(keyItem, player))) or 0
    if count > 0 and not item.stack then
        return {
            result   = false,
            error    = 2,
            money    = money._get(rds, item.currency),
            currency = item.currency,
            count    = count,
        }
    end
    local suc, _, new = money._cost(rds, player, item.currency, item.price)
    if not suc then
        return {
            result   = false,
            error    = 1,
            money    = new,
            currency = item.currency,
            count    = count,
        }
    end
    count = rds:hincrby(keyItem, player, 1)
    return {
        result   = true,
        error    = 0,
        money    = new,
        currency = item.currency,
        count    = count,
    }
end

function m._get(rds, player, name)
    return tonumber((rds:hget(KEY.ITEM .. name, player))) or 0
end

function m.get(rds, data)
    local player = data.player
    local name   = data.name
    return m._get(rds, player, name)
end

function m.use(rds, data)
    local player = data.player
    local name   = data.name
    local item   = shop[name]
    if not item then
        return {
            result = false,
            error  = 1,
        }
    end
    if not item.stack then
        return {
            result = false,
            error  = 3,
        }
    end
    local keyItem = KEY.ITEM .. name
    local count = rds:hincrby(keyItem, player, -1)
    if count < 0 then
        rds:hincrby(keyItem, player, 1)
        return {
            result = false,
            error  = 2,
            count  = count + 1,
        }
    end
    return {
        result = true,
        error  = 0,
        count  = count,
    }
end

function m.getAllInfo(rds, data)
    return shop
end

return m
