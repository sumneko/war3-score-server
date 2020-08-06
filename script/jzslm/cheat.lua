local KEY   = require 'script.jzslm.key'
local redis = require 'script.redis'
local util  = require 'script.utility'
local log   = require 'script.log'

local CHEAT_TIME = 14 * 60
local CHEAT_MAX  = 10

local m = {}

function m.checkTime(time)
    return time <= CHEAT_TIME
end

function m.mark(names)
    local rds = redis.get()
    for _, name in ipairs(names) do
        if #names == 1 then
            ngx.log(ngx.WARN, '作弊：', name, ' + 10')
            rds:hincrby(KEY.CHEAT, name, 10)
        else
            ngx.log(ngx.WARN, '作弊：', name, ' + 1')
            rds:hincrby(KEY.CHEAT, name, 1)
        end
    end
end

function m.isBlack(names)
    local rds = redis.get()
    for _, name in ipairs(names) do
        local c = tonumber((rds:hget(KEY.CHEAT, name))) or 0
        if c < CHEAT_MAX then
            return false
        end
    end
    return true
end

function m.clear()
    local rds = redis.get()
    local f = log('logs\\cheat\\clear-1.log')
    local cheats = {}
    local uids = util.zrevrange(rds, KEY.GROUP_SCORE, 1, -1)
    f:write('=====旧的排行榜一览=====\n')
    for rank, uid in ipairs(uids) do
        local time    = tonumber((rds:hget(KEY.GROUP_TIME,  uid))) or -1
        local level   = tonumber((rds:hget(KEY.GROUP_LEVEL, uid))) or -1
        local qClass  = rds:hget(KEY.GROUP_CLASS, uid)
        if qClass == ngx.null then
            qClass = ''
        end
        local names   = util.unpackList(uid)
        if m.checkTime(time) then
            m.mark(names)
        end
        if m.isBlack(names) or m.checkTime(time) then
            cheats[#cheats+1] = {
                rank  = rank,
                uid   = uid,
                time  = time,
                level = level,
                class = qClass,
                names = names,
            }
        end
        f:write('Rank:', rank
            , '\tUID:',   uid
            , '\tclass:', qClass
            , '\tLevel:', level
            , '\tTime:',  time
            , '\n'
        )
    end

    f:write('=====清理以下用户=====\n')
    for _, cheat in ipairs(cheats) do
        f:write('Rank:', cheat.rank
            , '\tUID:',   cheat.uid
            , '\tclass:', cheat.class
            , '\tLevel:', cheat.level
            , '\tTime:',  cheat.time
            , '\n'
        )
        rds:zrem(KEY.GROUP_SCORE, cheat.uid)
        rds:hdel(KEY.GROUP_CLASS, cheat.uid)
        rds:hdel(KEY.GROUP_TIME,  cheat.uid)
        rds:hdel(KEY.GROUP_LEVEL, cheat.uid)
        for _, name in ipairs(cheat.names) do
            rds:hdel(KEY.PLAYER_SCORE, name)
            rds:hdel(KEY.PLAYER_CLASS, name)
            rds:hdel(KEY.PLAYER_TIME,  name)
            rds:hdel(KEY.PLAYER_LEVEL, name)
        end
    end

    f:write('=====新的排行榜一览=====\n')
    local uids = util.zrevrange(rds, KEY.GROUP_SCORE, 1, -1)
    local mark = {}
    for rank, uid in ipairs(uids) do
        local time    = tonumber((rds:hget(KEY.GROUP_TIME,  uid))) or -1
        local level   = tonumber((rds:hget(KEY.GROUP_LEVEL, uid))) or -1
        local qClass  = rds:hget(KEY.GROUP_CLASS, uid)
        if qClass == ngx.null then
            qClass = ''
        end
        f:write('Rank:', rank
            , '\tUID:',   uid
            , '\tclass:', qClass
            , '\tLevel:', level
            , '\tTime:',  time
            , '\n'
        )
        local names   = util.unpackList(uid)
        local class   = util.unpackList(qClass)
        local score   = tonumber((rds:zscore(KEY.GROUP_SCORE, uid))) or -1
        for i, name in ipairs(names) do
            if not mark[name] then
                mark[name] = true
                rds:hset(KEY.PLAYER_SCORE, name, score)
                rds:hset(KEY.PLAYER_CLASS, name, class[i])
                rds:hset(KEY.PLAYER_TIME,  name, time)
                rds:hset(KEY.PLAYER_LEVEL, name, level)
            end
        end
    end
    f:close()
end

return m
