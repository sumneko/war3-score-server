local timer = require 'script.timer'
local redis = require 'script.redis'
local util  = require 'script.utility'
local KEY   = require 'script.jzslm.key'
local money = require 'script.jzslm.money'

local speedReward = {
    {  1,       100},
    {  2,        64},
    {  3,        47},
    { 10,        35},
    {100,        28},
    {500,        23},
    {math.huge,  20},
}

local function checkAward(time, date)
    if date.hour == 17 and date.min == 35 and date.sec == 0 then
        local red = redis.get()
        os.execute('md logs/reward')
        local f = io.open(('logs/reward/%04d-%02d-%02d.log'):format(
            date.year,
            date.month,
            date.day
        ), 'wb')

        -- 计算每个玩家在排行榜中的最高名次
        if f then
            f:write('=====排行榜一览=====\n')
        end
        local maxRank = {}
        local uids = util.zrevrange(red, KEY.GROUP_SCORE, 1, -1)
        for rank, uid in ipairs(uids) do
            if f then
                f:write(rank, '\t', uid, '\n')
            end
            local players = util.unpackList(uid)
            for _, player in ipairs(players) do
                if not maxRank[player] or maxRank[player] > rank then
                    maxRank[player] = rank
                end
            end
        end

        -- 根据每个玩家的最高名次来发送奖励
        if f then
            f:write('=====玩家一览=====\n')
        end
        for player, rank in pairs(maxRank) do
            if f then
                f:write(player, '\t', rank, '\n')
            end
            for level, data in ipairs(speedReward) do
                if rank <= data[1] then
                    if f then
                        f:write('\t', level, '\n', data[2], '\n')
                    end
                    money.add(red, player, '声望', data[2])
                    break
                end
            end
        end
        if f then
            f:close()
        end
    end
end

timer.onTick(function (time, date)
    ngx.log(ngx.INFO, time)
    checkAward(time, date)
end)
