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

function m.test()
    doRedis(function (red)
        local res, err = red:get 'test'
        if not res then
            ngx.say(err)
            return
        end

        local newValue = (tonumber(res) or 0) + 1
        local ok, err = red:set('test', newValue)
        if not ok then
            ngx.say(err)
            return
        end

        ngx.say('test = ', newValue)
    end)
end

return m
