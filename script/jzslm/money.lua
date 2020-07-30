local timer = require 'script.timer'
local redis = require 'script.redis'
local util  = require 'script.utility'
local KEY   = require 'script.jzslm.key'

local speedReward = {
    {  1,       100},
    {  2,        64},
    {  3,        47},
    { 10,        35},
    {100,        28},
    {500,        23},
    {math.huge,  20},
}

local m = {}

local function addMoney(red, player, name, value)
    red:hincrbyfloat(KEY.MONEY .. name, player, value)
end

local function getMoney(red, player, name)
    return tonumber(red:hget(KEY.MONEY .. name, player)) or 0
end

function m.get(red, data)
    return getMoney(red, data.player, data.name)
end

local function checkAward(time, date)
    if date.hour == 23 and date.min == 50 and date.sec == 0 then
        local red = redis.get()
        local groups = red:get(KEY.GROUPS)
        if groups == ngx.null then
            return
        end
        local list = util.unpackList(groups)

        -- 计算每个玩家在所有排行榜中的最高名次
        local maxRank = {}
        for _, group in ipairs(list) do
            local uids = util.zrange(red, KEY.GROUP_TIME .. group, 1, -1)
            for rank, uid in ipairs(uids) do
                local players = util.unpackList(uid)
                for _, player in ipairs(players) do
                    if not maxRank[player] or maxRank[player] > rank then
                        maxRank[player] = rank
                    end
                end
            end
        end

        -- 根据每个玩家的最高名次来发送奖励
        for player, rank in pairs(maxRank) do
            for _, data in ipairs(speedReward) do
                if rank <= data[1] then
                    addMoney(red, player, '声望', data[2])
                    break
                end
            end
        end
    end
end

timer.onTick(function ()
    checkAward()
end)

return m
