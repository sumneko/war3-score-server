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
    if not data.price or not data.currency then
        error('物品配置错误：' .. data.name)
    end
    -- 不可堆叠的物品只能买一次
    local count = tonumber(rds:hget(keyItem, player)) or 0
    if count > 0 and not item.stack then
        return {
            result   = false,
            error    = 2,
            money    = money._get(rds, data.currency),
            currency = data.currency,
            count    = count,
        }
    end
    local suc, _, new = money._cost(rds, player, data.currency, data.price)
    if not suc then
        return {
            result   = false,
            error    = 1,
            money    = new,
            currency = data.currency,
            count    = count,
        }
    end
    count = rds:hincrbyfloat(keyItem, player, 1)
    return {
        result   = true,
        error    = 0,
        money    = new,
        currency = data.currency,
        count    = count,
    }
end

function m.get(rds, data)
    local player = data.player
    local name   = data.name
    return tonumber(rds:hget(KEY.ITEM .. name, player))
end

function m.getAllInfo(rds, data)
    return shop
end

return m
