local redis = require "resty.redis"

local function doRedis(callback)
    local red = redis:new()

    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.say("failed to connect: ", err)
        return
    end

    callback(red)

    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end
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

return m
