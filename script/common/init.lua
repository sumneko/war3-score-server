local messager = require 'script.messager'
local code     = require 'script.code'
local redis    = require 'script.redis'
local cheat    = require 'script.common.cheat'

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
    if data.type == 'cheat' then
        return redis.call(cheat.report, data.value)
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
}
