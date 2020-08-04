local timer = require 'script.timer'
local redis = require 'script.redis'
local util  = require 'script.utility'
local KEY   = require 'script.jzslm.key'
local money = require 'script.jzslm.money'
local item  = require 'script.jzslm.item'
local camp  = require 'script.jzslm.camp'
local log   = require 'script.log'

local speedReward = {
    {  1,       100},
    {  2,        64},
    {  3,        47},
    { 10,        35},
    {100,        28},
    {500,        23},
    {math.huge,  20},
}

local function checkAwardBySpeed(time, date)
    if  date.hour == 23
    and date.min == 50
    and date.sec == 00 then
        ngx.log(ngx.INFO, '进行排名结算！')
        local red = redis.get()
        local f = log(('logs\\reward\\%04d-%02d-%02d.log'):format(
            date.year,
            date.month,
            date.day
        ))

        -- 计算每个玩家在排行榜中的最高名次
        f:write('=====排行榜一览=====\n')
        local maxRank = {}
        local uids = util.zrevrange(red, KEY.GROUP_SCORE, 1, -1)
        for rank, uid in ipairs(uids) do
            f:write(rank, '\t', uid, '\n')
            local players = util.unpackList(uid)
            for _, player in ipairs(players) do
                if not maxRank[player] or maxRank[player] > rank then
                    maxRank[player] = rank
                end
            end
        end

        -- 根据每个玩家的最高名次来发送奖励
        f:write('=====玩家一览=====\n')
        local sortedRank = {}
        for player in pairs(maxRank) do
            sortedRank[#sortedRank+1] = player
        end
        table.sort(sortedRank, function (a, b)
            return maxRank[a] < maxRank[b]
        end)
        for _, player in pairs(sortedRank) do
            local rank = maxRank[player]
            f:write(rank, '\t', player, '\n')
            for level, data in ipairs(speedReward) do
                if rank <= data[1] then
                    local selfReward = data[2]
                    local campReward = data[2]
                    local campName   = camp._get(red, player)
                    local hasFlag = item._get(red, player, '联盟战旗') > 0
                                or  item._get(red, player, '部落战旗') > 0
                    if hasFlag then
                        campReward = campReward * 1.1
                    end
                    if campName then
                        camp._addMoney(red, campName, '声望', campReward)
                    end
                    f:write('\t档位：',    level)
                    f:write('\t个人奖励：', selfReward)
                    f:write('\t阵营奖励：', campReward)
                    f:write('\t有战旗：',   tostring(hasFlag))
                    f:write('\t所属阵营：', tostring(campName))
                    f:write('\n')
                    money._add(red, player, '声望', selfReward)
                    break
                end
            end
        end

        f:write('=====阵营声望=====\n')
        for _, campName in ipairs {'联盟', '部落'} do
            local value = camp._getMoney(red, campName, '声望')
            f:write(campName, '\t', value, '\n')
        end
        f:close()
    end
end

local function checkAwardByItem(time, date)
    if  date.hour == 23
    and date.min == 50
    and date.sec == 05 then
        ngx.log(ngx.INFO, '进行战旗奖励结算！')
        local red = redis.get()
        local f = log(('logs\\reward-item\\%04d-%02d-%02d.log'):format(
            date.year,
            date.month,
            date.day
        ))

        f:write('=====战旗一览=====\n')
        for _, name in ipairs {'联盟战旗', '部落战旗'} do
            f:write('-----', name, '-----\n')
            local key = KEY.ITEM .. name
            local values = util.hgetall(red, key)
            for player, value in pairs(values) do
                local count = tonumber(value) or 0
                if count > 0 then
                    f:write(player, '\n')
                    money._add(red, player, '声望', 5)
                end
            end
        end
        f:close()
    end
end

local function checkClear(time, date)
    -- wday == 1 是周日
    if  date.wday == 1
    and date.hour == 23
    and date.min == 50
    and date.sec == 15 then
        ngx.log(ngx.INFO, '清空排行榜！')
        local red = redis.get()
        red:del(KEY.GROUP_SCORE)
        red:del(KEY.GROUP_CLASS)
        red:del(KEY.GROUP_TIME)
        red:del(KEY.GROUP_LEVEL)
        red:del(KEY.PLAYER_SCORE)
        red:del(KEY.PLAYER_CLASS)
        red:del(KEY.PLAYER_TIME)
        red:del(KEY.PLAYER_LEVEL)
    end
end

timer.onTick(function (time, date)
    checkAwardBySpeed(time, date)
    checkAwardByItem(time, date)
    checkClear(time, date)
end)
