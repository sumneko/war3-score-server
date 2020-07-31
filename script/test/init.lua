local messager = require 'script.messager'
local code     = require 'script.code'
local redis    = require 'script.redis'
local score    = require 'script.test.score'

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
    if data.type == 'ping' then
        return redis.call(score.ping, data)
    elseif data.type == 'hello' then
        return redis.call(score.hello, data)
    end
    error('Unknown proto:' .. tostring(data.type))
end

local suc, res = xpcall(call, debug.traceback)
if not suc then
    ngx.log(ngx.ERR, res)
    messager.response {
        result  = false,
        error   = code.ERROR_RUNTIME,
        message = err,
    }
    return
end

messager.response {
    result = true,
    value  = res,
}
