local KEY = require 'script.jzslm.key'
local shop = require 'script.jzslm.shop'

local m = {}

function m.buyItem()
end

function m.getItem(rds, data)
    local player = data.player
    local name   = data.name
    return tonumber(rds:hget(KEY.ITEM .. name, player))
end

return m
