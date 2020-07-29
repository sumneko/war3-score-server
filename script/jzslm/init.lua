local messager = require 'script.messager'
local redis    = require 'script.redis'
local speed    = require 'script.jzslm.speed'

local data = messager.recive()
if not data then
    return
end
local response
if data.type == 'speedReport' then
    response = redis(speed.report, data.value)
elseif data.type == 'getSpeedRank' then
    response = redis(speed.getRank, data.value)
else
    response = ('Unkown Data Type: %s'):format(data.type)
end

messager.response(response)
