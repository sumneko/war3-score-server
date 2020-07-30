local messager = require 'script.messager'
local redis    = require 'script.redis'
local speed    = require 'script.jzslm.speed'
local money    = require 'script.jzslm.money'

local data = messager.recive()
if not data then
    return
end
local response
if data.type == 'speedReport' then
    response = redis.call(speed.report, data.value)
elseif data.type == 'getPlayerSpeed' then
    response = redis.call(speed.get, data.value)
elseif data.type == 'getSpeedRank' then
    response = redis.call(speed.getRank, data.value)
elseif data.type == 'getMoney' then
    response = redis.call(money.get, data.value)
else
    return
end

if type(response) == 'table' then
    response.request = data.type
end
messager.response(response)
