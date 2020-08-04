local messager = require 'script.messager'
local code     = require 'script.code'
local redis    = require 'script.redis'
local speed    = require 'script.jzslm.speed'
local money    = require 'script.jzslm.money'
local item     = require 'script.jzslm.item'
local camp     = require 'script.jzslm.camp'

local data, err = messager.recive()
if not data then
    ngx.log(ngx.WARN, err)
    messager.response {
        result  = false,
        error   = code.ERROR_PROTO_ERROR,
        message = err,
    }
    return
end

local function call()
    if data.type == 'speedReport' then
        return redis.call(speed.report, data.value)
    elseif data.type == 'getPlayerSpeed' then
        return redis.call(speed.get, data.value)
    elseif data.type == 'getSpeedRank' then
        return redis.call(speed.getRank, data.value)
    elseif data.type == 'getMoney' then
        return redis.call(money.get, data.value)
    elseif data.type == 'costMoney' then
        return redis.call(money.cost, data.value)
    elseif data.type == 'getCamp' then
        return redis.call(camp.get, data.value)
    elseif data.type == 'setCamp' then
        return redis.call(camp.set, data.value)
    elseif data.type == 'buyItem' then
        return redis.call(item.buy, data.value)
    elseif data.type == 'getItem' then
        return redis.call(item.get, data.value)
    elseif data.type == 'getAllItemInfo' then
        return redis.call(item.getAllInfo, data.value)
    end
    error('Unknown proto:' .. tostring(data.type))
end

local suc, res = xpcall(call, debug.traceback)
if not suc then
    ngx.log(ngx.ERR, res)
    messager.response {
        request = data.type,
        result  = false,
        error   = code.ERROR_RUNTIME,
        message = res,
    }
    return
end

messager.response {
    request = data.type,
    result  = true,
    value   = res,
    -- TODO
    _0x018F_ = true,
}
