local util  = require 'script.utility'
local KEY   = require 'script.jzslm.key'
local cheat = require 'script.jzslm.cheat'

local m = {}

local function getGroupUIDandClass(players)
    local names = {}
    local classMap = {}
    for _, player in pairs(players) do
        local qName = ('%q'):format(player.name)
        local qClass = ('%q'):format(player.class)
        names[#names+1] = qName
        classMap[qName] = qClass
    end
    table.sort(names)
    local class = {}
    for _, name in ipairs(names) do
        class[#class+1] = classMap[name]
    end
    return table.concat(names, ','), table.concat(class, ',')
end

local function checkGroupRecord(redis, data, newScore)
    local uid, class = getGroupUIDandClass(data.players)
    local names = util.unpackList(uid)
    -- 检查作弊
    if cheat.checkTime(data.level, data.time) then
        cheat.mark(util.unpackList(uid))
        return {
            name   = uid,
            class  = class,
            result = false,
        }
    end
    if cheat.isBlack(names) then
        return {
            name   = uid,
            class  = class,
            result = false,
        }
    end
    local oldScore   = tonumber(redis:zscore(KEY.GROUP_SCORE, uid))
    if oldScore and oldScore >= newScore then
        return {
            name   = uid,
            class  = class,
            result = false,
        }
    else
        local oldTime  = tonumber((redis:hget(KEY.GROUP_TIME,  uid)))
        local oldLevel = tonumber((redis:hget(KEY.GROUP_LEVEL, uid)))
        redis:zadd(KEY.GROUP_SCORE, newScore, uid)
        redis:hset(KEY.GROUP_CLASS, uid,      class)
        redis:hset(KEY.GROUP_TIME,  uid,      data.time)
        redis:hset(KEY.GROUP_LEVEL, uid,      data.level)
        return {
            name   = uid,
            class  = class,
            result = true,
            old    = oldScore and {
                level = oldLevel,
                time  = oldTime,
            },
            new    = {
                level = data.level,
                time  = data.time,
            },
        }
    end
end

local function checkPlayersRecord(redis, data, newScore, suc)
    local results  = {}
    for _, player in pairs(data.players) do
        local name     = player.name
        local class    = player.class
        local oldScore = tonumber((redis:hget(KEY.PLAYER_SCORE, name)))
        if (oldScore and oldScore >= newScore)
        or not suc then
            results[name] = {
                name   = name,
                class  = class,
                result = false,
            }
        else
            local oldTime  = tonumber((redis:hget(KEY.PLAYER_TIME,  name)))
            local oldLevel = tonumber((redis:hget(KEY.PLAYER_LEVEL, name)))
            redis:hset(KEY.PLAYER_SCORE, name, newScore)
            redis:hset(KEY.PLAYER_CLASS, name, class)
            redis:hset(KEY.PLAYER_TIME,  name, data.time)
            redis:hset(KEY.PLAYER_LEVEL, name, data.level)
            results[name] = {
                name   = name,
                class  = class,
                result = true,
                old    = oldScore and {
                    level = oldLevel,
                    time  = oldTime,
                },
                new    = {
                    level = data.level,
                    time  = data.time,
                },
            }
        end
    end
    return results
end

function m.report(redis, data)
    local score       = data.level * 3600 - data.time -- 每层领先1个小时
    local groupData   = checkGroupRecord(redis, data, score)
    local playersData = checkPlayersRecord(redis, data, score, groupData.result)
    return {
        group   = groupData,
        players = playersData,
    }
end

local function findPlayerRank(redis, player)
    local score = tonumber((redis:hget(KEY.PLAYER_SCORE, player)))
    if not score then
        return nil
    end
    local uids  = util.zrevrangebyscore(redis, KEY.GROUP_SCORE, score, score)
    for _, uid in ipairs(uids) do
        local players = util.unpackList(uid)
        for i = 1, #players do
            if players[i] == player then
                local rank = tonumber((redis:zrevrank(KEY.GROUP_SCORE, uid)))
                if not rank then
                    return nil
                end
                return rank + 1
            end
        end
    end
    return nil
end

function m.get(redis, data)
    local player = data.player
    local time = tonumber((redis:hget(KEY.PLAYER_TIME, player)))
    if time then
        return {
            time  = time,
            level = tonumber((redis:hget(KEY.PLAYER_LEVEL, player))),
            class = redis:hget(KEY.PLAYER_CLASS, player),
            rank  = findPlayerRank(redis, player),
        }
    else
        return nil
    end
end

function m.getRank(redis, data)
    local results = {}
    local uids = util.zrevrange(redis, KEY.GROUP_SCORE, data.start, data.finish)
    for i, uid in ipairs(uids) do
        local time    = tonumber((redis:hget(KEY.GROUP_TIME,  uid)))
        local level   = tonumber((redis:hget(KEY.GROUP_LEVEL, uid)))
        local qClass  = redis:hget(KEY.GROUP_CLASS, uid)
        local names   = util.unpackList(uid)
        local class   = util.unpackList(qClass)
        local players = {}
        -- 过滤作弊
        if cheat.checkTime(level, time) then
            names = {'|cffff1111该用户已被封禁，稍后将被移出排行榜，欢迎举报！|r'}
            class = {'无'}
        end
        for x, name in ipairs(names) do
            players[x] = {
                name  = name,
                class = class[x]
            }
        end
        results[i] = {
            rank    = data.start + i - 1,
            level   = level,
            time    = time,
            players = players,
        }
    end
    return results
end

return m
