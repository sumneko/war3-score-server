local m = {}

local KEY_GROUP_TIME   = 'jzslm:speed.group.time'
local KEY_PLAYER_TIME  = 'jzslm:speed.player.time'
local KEY_GROUP_CLASS  = 'jzslm:speed.group.class.'
local KEY_PLAYER_CLASS = 'jzslm:speed.player.class.'

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

local function checkGroupRecord(redis, data)
    local uid, class = getGroupUIDandClass(data.players)
    local keyTime    = KEY_GROUP_TIME .. data.group
    local keyClass   = KEY_GROUP_CLASS .. data.group
    local newTime    = data.time
    local oldTime    = tonumber(redis:zscore(keyTime, uid))
    if oldTime and oldTime <= newTime then
        return {
            name   = uid,
            class  = class,
            result = false,
            old    = oldTime,
            new    = newTime,
        }
    else
        redis:zadd(keyTime, ('%.3f'):format(newTime), uid)
        redis:hset(keyClass, uid, class)
        return {
            name   = uid,
            class  = class,
            result = true,
            old    = oldTime,
            new    = newTime,
        }
    end
end

local function checkPlayersRecord(redis, data)
    local keyTime  = KEY_PLAYER_TIME .. data.group
    local keyClass = KEY_PLAYER_CLASS .. data.group
    local newTime  = data.time
    local results  = {}
    for _, player in pairs(data.players) do
        local name    = player.name
        local class   = player.class
        local oldTime = tonumber(redis:hget(keyTime, name))
        if oldTime and oldTime <= newTime then
            results[name] = {
                name   = name,
                class  = class,
                result = false,
                old    = oldTime,
                new    = newTime,
            }
        else
            redis:hset(keyTime, name, ('%.3f'):format(newTime))
            redis:hset(keyClass, name, class)
            results[name] = {
                name   = name,
                class  = class,
                result = true,
                old    = oldTime,
                new    = newTime,
            }
        end
    end
    return results
end

function m.report(redis, data)
    local groupData = checkGroupRecord(redis, data)
    local playersData = checkPlayersRecord(redis, data)
    return {
        group   = groupData,
        players = playersData,
    }
end

function m.get(redis, data)
    local keyTime  = KEY_PLAYER_TIME .. data.group
    local keyClass = KEY_PLAYER_CLASS .. data.group
    local player   = data.player
    local time = tonumber(redis:hget(keyTime, player))
    if time then
        local class = redis:hget(keyClass, player)
        return {
            time  = time,
            class = class,
        }
    else
        return nil
    end
end

function m.getRank(redis, range)
end

return m
