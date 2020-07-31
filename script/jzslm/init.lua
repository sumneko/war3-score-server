local messager = require 'script.messager'
local code     = require 'script.code'
local redis    = require 'script.redis'
local speed    = require 'script.jzslm.speed'
local money    = require 'script.jzslm.money'

local data, err = messager.recive()
if not data then
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
        message = err,
    }
    return
end

messager.response {
    request = data.type,
    result  = true,
    value   = res,
}
