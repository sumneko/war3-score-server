local messager = require 'script.messager'
local redis    = require 'script.redis'
local score    = require 'script.test.score'

local data = messager.recive()
if not data then
    return
end
local response
if data.type == 'ping' then
    response = redis(score.ping, data)
elseif data.type == 'hello' then
    response = redis(score.hello, data)
else
    response = ('Unkown Data Type: %s'):format(data.type)
end

messager.response(response)
