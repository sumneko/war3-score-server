local redis = require "resty.redis"

local function doRedis(callback)
    local red = redis:new()

    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("failed to connect: ", err)
        return
    end

    local res = callback(red)

    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end

    return res
end

local m = {}

function m.test(data)
    doRedis(function (red)
        local ok, err = red:incrby('test', 10)
        if not ok then
            ngx.say(err)
            return
        end

        ngx.say('test = ', red:get('test'))
    end)
end

function m.ping(data)
    return {
        type  = 'pong',
        value = ('hello %s!'):format(data.value),
    }
end

function m.hello(data)
    local ip = ngx.var.remote_addr
    return doRedis(function (red)
        red:hincrby('hello', ip, 1)
        return {
            type = 'print',
            value = ('你好，来自 %s 的 %s ，你已成功连接服务器。这是你的第 %d 次连接。'):format(ip, data.value, red:hget('hello', ip))
        }
    end)
end

return m
