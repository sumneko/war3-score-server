local timer = require 'script.timer'
local redis = require 'script.redis'
local util  = require 'script.utility'
local KEY   = require 'script.jzslm.key'
local money = require 'script.jzslm.money'
local item  = require 'script.jzslm.item'
local camp  = require 'script.jzslm.camp'
local cheat = require 'script.jzslm.cheat'
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

local function awardBySpeed(time, date)
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
                    camp._addMoney(red, campName, '积分', campReward)
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

    f:write('=====阵营积分=====\n')
    for _, campName in ipairs {'联盟', '部落'} do
        local value = camp._getMoney(red, campName, '积分')
        f:write(campName, '\t', value, '\n')
    end
    f:close()
end

local function awardByItem(time, date)
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

local function awardByCamp(time, date)
    ngx.log(ngx.INFO, '进行阵营奖励结算！')
    local red = redis.get()
    local f = log(('logs\\reward-camp\\%04d-%02d-%02d.log'):format(
        date.year,
        date.month,
        date.day
    ))

    local value1 = camp._getMoney(red, '联盟', '积分')
    local value2 = camp._getMoney(red, '部落', '积分')
    camp._addMoney(red, '联盟', '积分', -value1)
    camp._addMoney(red, '部落', '积分', -value2)

    f:write('联盟积分：', value1, '\n')
    f:write('部落积分：', value2, '\n')

    local reward1, reward2
    if value1 == value2 then
        reward1 = 75
        reward2 = 75
    elseif value1 < value2 then
        reward2 = 150
    else
        reward1 = 150
    end

    f:write('=====开始发积分=====\n')
    local values = util.hgetall(red, KEY.CAMP)
    for player, campName in pairs(values) do
        if campName == '联盟' and reward1 then
            f:write('联盟\t', player, '：\t', reward1, '\n')
            money._add(red, player, '声望', reward1)
        elseif campName == '部落' and reward2 then
            f:write('部落\t', player, '：\t', reward2, '\n')
            money._add(red, player, '声望', reward2)
        end
    end

    f:close()
end

local function clearSpeed(time, date)
    -- wday == 1 是周日
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

local MARK
local function test(time, date)
    if MARK then
        return
    end
    MARK = true
    local rds = redis.get()
    --money._add(red, 'WorldEdit', '声望', 10000)
    cheat.view()
end

timer.onTick(function (time, date)
    test(time, date)

    if  date.hour == 23
    and date.min == 50
    and date.sec == 00 then
        awardBySpeed(time, date)
    end

    if  date.hour == 23
    and date.min == 50
    and date.sec == 05 then
        awardByItem(time, date)
    end

    -- wday == 1 是周日
    if  date.wday == 1
    and date.hour == 23
    and date.min == 50
    and date.sec == 10 then
        awardByCamp(time, date)
    end

    -- wday == 1 是周日
    if  date.wday == 1
    and date.hour == 23
    and date.min == 50
    and date.sec == 15 then
        clearSpeed(time, date)
    end
end)
